defmodule Lagrange.WorkerToGwResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.13.0", syntax: :proto3

  field :task_id, 1, type: Lagrange.UUID, json_name: "taskId"
  field :task, 2, type: :bytes
end

defmodule Lagrange.WorkerReady do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.13.0", syntax: :proto3

  field :version, 1, type: :string
  field :worker_class, 2, type: :string, json_name: "workerClass"
end

defmodule Lagrange.WorkerToGwRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.13.0", syntax: :proto3

  oneof :request, 0

  field :worker_ready, 1, type: Lagrange.WorkerReady, json_name: "workerReady", oneof: 0
  field :worker_done, 2, type: Lagrange.WorkerDone, json_name: "workerDone", oneof: 0
end

defmodule Lagrange.WorkerDone do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.13.0", syntax: :proto3

  oneof :reply, 0

  field :task_id, 1, type: Lagrange.UUID, json_name: "taskId"
  field :task_output, 2, type: :bytes, json_name: "taskOutput", oneof: 0
  field :worker_error, 3, type: :string, json_name: "workerError", oneof: 0
end

defmodule Lagrange.UUID do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.13.0", syntax: :proto3

  field :id, 1, type: :bytes
end

defmodule Lagrange.SubmitTaskRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.13.0", syntax: :proto3

  field :task_bytes, 1, type: :bytes, json_name: "taskBytes"
  field :user_task_id, 2, type: :string, json_name: "userTaskId"
  field :timeout, 3, type: Google.Protobuf.Timestamp
  field :price_requested, 4, type: :bytes, json_name: "priceRequested"
  field :class, 5, type: :string
end

defmodule Lagrange.SubmitTaskResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.13.0", syntax: :proto3

  oneof :reply, 0

  field :reply_string, 1, type: :string, json_name: "replyString", oneof: 0
  field :task_uuid, 2, type: Lagrange.UUID, json_name: "taskUuid"
end

defmodule Lagrange.AckedMessages do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.13.0", syntax: :proto3

  field :acked_messages, 1, repeated: true, type: Lagrange.UUID, json_name: "ackedMessages"
end

defmodule Lagrange.SubscribeToMessages do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.13.0", syntax: :proto3

  field :subscribe_to_messages, 2,
    repeated: true,
    type: Lagrange.UUID,
    json_name: "subscribeToMessages"
end

defmodule Lagrange.ProofChannelRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.13.0", syntax: :proto3

  oneof :request, 0

  field :acked_messages, 1, type: Lagrange.AckedMessages, json_name: "ackedMessages", oneof: 0

  field :subscribe_to_messages, 2,
    type: Lagrange.SubscribeToMessages,
    json_name: "subscribeToMessages",
    oneof: 0
end

defmodule Lagrange.ProofReady do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.13.0", syntax: :proto3

  field :task_id, 1, type: Lagrange.UUID, json_name: "taskId"
  field :task_output, 2, type: :bytes, json_name: "taskOutput"
end

defmodule Lagrange.ProofChannelResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.13.0", syntax: :proto3

  oneof :response, 0

  field :proof, 1, type: Lagrange.ProofReady, oneof: 0
end

defmodule Lagrange.WorkersService.Service do
  @moduledoc false

  use GRPC.Service, name: "lagrange.WorkersService", protoc_gen_elixir_version: "0.13.0"

  rpc :WorkerToGw, stream(Lagrange.WorkerToGwRequest), stream(Lagrange.WorkerToGwResponse)
end

defmodule Lagrange.WorkersService.Stub do
  @moduledoc false

  use GRPC.Stub, service: Lagrange.WorkersService.Service
end

defmodule Lagrange.ClientsService.Service do
  @moduledoc false

  use GRPC.Service, name: "lagrange.ClientsService", protoc_gen_elixir_version: "0.13.0"

  rpc :SubmitTask, Lagrange.SubmitTaskRequest, Lagrange.SubmitTaskResponse

  rpc :ProofChannel, stream(Lagrange.ProofChannelRequest), stream(Lagrange.ProofChannelResponse)
end

defmodule Lagrange.ClientsService.Stub do
  @moduledoc false

  use GRPC.Stub, service: Lagrange.ClientsService.Service
end