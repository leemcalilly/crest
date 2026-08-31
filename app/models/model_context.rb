# The catalog of tools this site offers an agent looking at one of its pages.
#
# WebMCP is a new mouth on the existing body: no tool has query logic of its
# own. Read tools fetch the page's own JSON URLs; page tools act on live
# browser state and have no server counterpart.
module ModelContext
  def self.global = Manifest::GLOBAL
end
