module Lita
  module Handlers
    class Kokodeikku < Handler
      route(/.*/, :kokodeikku)

      def kokodeikku(response)
        if !response.matches[0].start_with?("#{prefix} ") && (song = reviewer.find(response.matches[0]))
          response.reply("#{prefix} #{song.phrases.map(&:join).join(' ')}")
        end
      end

      def prefix
        "ここで一句"
      end

      def reviewer
        @reviewer ||= Ikku::Reviewer.new(rule: rule)
      end

      def rule
        if "5,7,5"
          "5,7,5".split(",").map(&:to_i)
        end
      end

      Lita.register_handler(self)
    end
  end
end
