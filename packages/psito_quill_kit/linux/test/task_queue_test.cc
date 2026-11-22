#include "core/task_queue.h"

#include <gtest/gtest.h>

#include <atomic>
#include <mutex>
#include <thread>
#include <vector>

using pqk::TaskQueue;

TEST(TaskQueue, RunsTasksInOrderOnItsOwnThread) {
  std::vector<int> order;
  std::thread::id worker;
  {
    TaskQueue q("teste");
    for (int i = 0; i < 100; ++i)
      q.post([&, i] {
        order.push_back(i);
        worker = std::this_thread::get_id();
      });
    q.stop();
  }
  ASSERT_EQ(order.size(), 100u);
  for (int i = 0; i < 100; ++i) EXPECT_EQ(order[i], i);
  EXPECT_NE(worker, std::this_thread::get_id());
}

TEST(TaskQueue, PostNeverBlocksTheCaller) {
  TaskQueue q("lento");
  std::atomic<bool> release{false};
  q.post([&] {
    while (!release) std::this_thread::yield();
  });
  auto start = std::chrono::steady_clock::now();
  for (int i = 0; i < 1000; ++i) q.post([] {});
  auto ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - start).count();
  EXPECT_LT(ms, 50.0);
  EXPECT_GE(q.pending(), 1000u);
  release = true;
  q.stop();
  EXPECT_EQ(q.pending(), 0u);
}

TEST(TaskQueue, ManyProducersAreSerialized) {
  std::atomic<int> inside{0}, maxInside{0}, total{0};
  TaskQueue q("serial");
  std::vector<std::thread> producers;
  for (int p = 0; p < 4; ++p)
    producers.emplace_back([&] {
      for (int i = 0; i < 250; ++i)
        q.post([&] {
          int now = ++inside;
          maxInside = std::max(maxInside.load(), now);
          ++total;
          --inside;
        });
    });
  for (auto& t : producers) t.join();
  q.stop();
  EXPECT_EQ(total, 1000);
  EXPECT_EQ(maxInside, 1);  // nunca duas tarefas ao mesmo tempo (o LOK exige)
}

TEST(TaskQueue, PostAfterStopIsIgnored) {
  TaskQueue q("parada");
  q.stop();
  bool ran = false;
  q.post([&] { ran = true; });
  q.stop();
  EXPECT_FALSE(ran);
}

TEST(TaskQueue, TaskKnowsItIsOnTheQueueThread) {
  TaskQueue q("thread");
  std::atomic<bool> inside{false};
  q.post([&] { inside = q.isQueueThread(); });
  q.stop();
  EXPECT_TRUE(inside);
  EXPECT_FALSE(q.isQueueThread());
}
