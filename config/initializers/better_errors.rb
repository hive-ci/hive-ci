if defined?(BetterErrors)
  module BetterErrors
    class Middleware
      def allow_ip?(_env)
        Chamber.env.better_errors_for_all
      end
    end
  end
end
