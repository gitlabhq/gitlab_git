module Gitlab
  module Git
    class Tag < Ref
      attr_reader :message

      def initialize(name, target, message = nil)
        super(name, target)
        @message = message
      end
    end
  end
end
