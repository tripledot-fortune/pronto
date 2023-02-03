module Pronto
  module Formatter
    class GithubPullRequestReplyFormatter < GitFormatter
      def format(messages, repo, _patches)
        client = client_module.new(repo)

        existed_comment = client.issue_comments.find do |comment|
          comment[:author_association] == 'NONE' || comment[:user][:type] == 'Bot'
        end
        submit_comments(client, messages, existed_comment, client.pull_owner[:login])
        approve_pull_request(messages.count, messages.count, client) if defined?(approve_pull_request)

        "#{messages.count} Pronto messages posted to #{pretty_name} (#{messages.count} existing)"
      end

      def client_module
        Github
      end

      def pretty_name
        'GitHub'
      end

      def submit_comments(client, comments, existed_comment = nil, username)
        if comments.count.zero?
          congratulation_template = 'Congratulation!!🎉🎉🎉 🕵 Test coverage is OK and your code looks good 🤘!'

          client.delete_issue_comment(existed_comment[:id]) if existed_comment
          client.add_comment(congratulation_template)
        else
          body = "🚨🚨🚨🚨🚓 Hey @#{username}🕵 This is the 🔫👮👮🚔👮\n```" << prepare_comments(comments).join("\n")

          if existed_comment
            client.update_comment(existed_comment[:id], body)
          else
            client.add_comment(body)
          end
        end
      rescue Octokit::UnprocessableEntity, HTTParty::Error => e
        $stderr.puts "Failed to post: #{e.message}"
      end

      def line_number(message, patches)
        line = patches.find_line(message.full_path, message.line.new_lineno)
        line.position
      end

      def prepare_comments(comments)
        comments.map do |message|
          message_format = '%{path}:%{line} - %{msg}'
          message_data = TextMessageDecorator.new(message).to_h
          (message_format % message_data).strip
        end
      end
    end
  end
end
