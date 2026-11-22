#include "task_queue.h"

#include <pthread.h>

namespace pqk {

TaskQueue::TaskQueue(std::string name) : name_(std::move(name)) {
  thread_ = std::thread([this] { run(); });
}

TaskQueue::~TaskQueue() { stop(); }

void TaskQueue::post(Task task) {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    if (stopping_) return;
    tasks_.push_back(std::move(task));
  }
  cv_.notify_one();
}

void TaskQueue::stop() {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    if (stopping_ && !thread_.joinable()) return;
    stopping_ = true;
  }
  cv_.notify_one();
  if (thread_.joinable() && !isQueueThread()) thread_.join();
}

bool TaskQueue::isQueueThread() const {
  return std::this_thread::get_id() == thread_.get_id();
}

size_t TaskQueue::pending() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return tasks_.size();
}

void TaskQueue::run() {
  // O nome aparece no top/gdb: "pqk-kit", "pqk-lua".
  pthread_setname_np(pthread_self(), name_.substr(0, 15).c_str());
  for (;;) {
    Task task;
    {
      std::unique_lock<std::mutex> lock(mutex_);
      cv_.wait(lock, [this] { return stopping_ || !tasks_.empty(); });
      if (tasks_.empty()) return;  // stopping_ e nada mais a fazer
      task = std::move(tasks_.front());
      tasks_.pop_front();
    }
    task();
  }
}

}  // namespace pqk
