# One tool descriptor: what the agent is told, and how the page runs it.
#
# `kind` is the seam. A :read tool fetches a same-origin URL. A :page tool
# moves the page itself — the thing a server tool cannot do.
class ModelContext::Tool
  attr_reader :name, :description, :schema, :kind, :action, :read_only

  def initialize(name:, description:, kind:, schema: {}, action: nil, read_only: true)
    @name = name
    @description = description
    @kind = kind
    @schema = schema
    @action = action
    @read_only = read_only
  end

  def as_json(options = nil)
    { name:, description:, kind:, action:,
      inputSchema: { type: "object", properties: schema,
                     required: schema.select { |_, v| v[:required] }.keys,
                     additionalProperties: false },
      annotations: { readOnlyHint: read_only, untrustedContentHint: false } }
  end
end
