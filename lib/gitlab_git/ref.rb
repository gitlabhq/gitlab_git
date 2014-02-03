module Gitlab
  module Git
    class Ref
      # Branch or tag name
      # without "refs/tags|heads" prefix
      attr_reader :name

      # Target sha.
      # Usually it is commit sha but in case
      # when tag reference on other tag it can be tag sha
      attr_reader :target

      def initialize(name, target)
        @name, @target = name.gsub(/\Arefs\/(tags|heads)\//, ''), target
      end
    end
  end
end
