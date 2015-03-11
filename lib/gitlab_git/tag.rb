module Gitlab
  module Git
    class Tag < Ref
      def initialize(name, target, message = nil)
        super(name, target)
        @message = message
      end

      def message
        encode! @message
      end
    end
  end
end
