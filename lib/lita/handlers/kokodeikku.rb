module Lita
  module Handlers
    class Kokodeikku < Handler
      TABLE_NAME = 'ikku'
      def connect
        Mysql2::Client.new(:host => 'localhost', :user => 'root', :password => 'root', :database => 'lita_kintai')
      end

      def datetime(time)
        time.strftime('%F %T')
      end
      
      def prev_month(time)
        if time.month == 1
          Time.new(time.year - 1, 12, 1)
        else
          Time.new(time.year, time.month - 1, 1)
        end
      end

      route(/^今月のハイカー$/, :monthly_singer)
      def monthly_singer(response)
        time = Time.now
        start_at = datetime(prev_month(time))
        end_at = datetime(Time.new(time.year, time.month, 1))
        client = connect
        select_query = "select id, count(ikku) as ik from #{TABLE_NAME} where moment_at between '#{start_at}' and '#{end_at}' group by id order by ik desc"
        result = client.query(select_query).first
        select_query = "select name from #{TABLE_NAME} where id = '#{result['id']}'"
        result2 = client.query(select_query).first
        reply = "先月の Haiker of The Month は #{result2['name']}さんです。 詠んだ俳句は #{result['ik']} 件でした。おめでとうございます。"
        response.reply(reply)
      end

      route(/^最新の一句$/, :resent_song)
      def resent_song(response)
        client = connect
        select_query = "select name, ikku from #{TABLE_NAME} order by moment_at desc"
        result = client.query(select_query).first
        reply = "最近の俳句は #{result['name']}さんの「 #{result['ikku']}」です。"
        response.reply(reply)
      end

      route(/.*/, :kokodeikku)
      def kokodeikku(response)
        if !response.matches[0].start_with?("#{prefix} ") && (song = reviewer.find(response.matches[0]))
          response.reply("#{prefix} #{song.phrases.map(&:join).join(' ')}")

          time = Time.now
          client = connect
          insert_query = "insert into #{TABLE_NAME} (id, name, ikku, moment_at) values('#{response.user.id}', '#{response.user.name}', '#{song.phrases.map(&:join).join(' ')}', '#{datetime(time)}')"
          client.query(insert_query)
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
