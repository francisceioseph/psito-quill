// Active Object: uma thread própria que executa tarefas em ordem.
//
// O LibreOfficeKit não é thread-safe. Toda chamada a ele vira uma tarefa
// nesta fila, e só a thread da fila fala com o motor. Quem posta nunca espera.
#pragma once

#include <condition_variable>
#include <deque>
#include <functional>
#include <mutex>
#include <string>
#include <thread>

namespace pqk {

class TaskQueue {
 public:
  using Task = std::function<void()>;

  explicit TaskQueue(std::string name);
  ~TaskQueue();

  TaskQueue(const TaskQueue&) = delete;
  TaskQueue& operator=(const TaskQueue&) = delete;

  // Põe a tarefa no fim da fila. Não bloqueia. Depois do stop(), é ignorada.
  void post(Task task);

  // Executa as tarefas que já estão na fila e encerra a thread. Idempotente.
  void stop();

  // true se chamado de dentro da thread da fila.
  bool isQueueThread() const;

  size_t pending() const;

 private:
  void run();

  std::string name_;
  mutable std::mutex mutex_;
  std::condition_variable cv_;
  std::deque<Task> tasks_;
  bool stopping_ = false;
  std::thread thread_;
};

}  // namespace pqk
