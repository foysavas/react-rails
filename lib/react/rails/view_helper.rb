module React
  module Rails
    module ViewHelper
      # Render a React component named +name+. Returns the server-rendered HTML
      # as well as javascript to activate the component client-side.
      # The HTML tag is +div+ by default and can be changed by +options[:tag]+.
      # If +options[:tag]+ is a symbol, use it as +options[:tag]+. HTML attributes
      # can be specified by +options+. The javascript will encode +args+ to JSON
      # and use it to construct the component.
      #
      # The server rendering requires you to have a +components.js+ file accessible to
      # Sprockets that contains all of your React components defined along with any code
      # necessary for React to server render them.
      #
      # ==== Examples
      #
      #   # // <HelloMessage> defined in a .jsx file:
      #   # var HelloMessage = React.createClass({
      #   #   render: function() {
      #   #     return <div>{'Hello ' + this.props.name}</div>;
      #   #   }
      #   # });
      #   react_component(:HelloMessage, :name => 'John')
      #
      #   # Use <span> instead of <div>:
      #   react_component(:HelloMessage, {:name => 'John'}, :span)
      #   react_component(:HelloMessage, {:name => 'John'}, :tag => :span)
      #
      #   # Add HTML attributes:
      #   react_component(:HelloMessage, {}, {:class => 'c', :id => 'i'})
      #
      def react_component(name, args = {}, options = {})
        html_tag, html_options = *react_parse_options(options)
        result = content_tag(html_tag, react_html(name, args), html_options)
        result << react_javascript_tag(name, html_options[:id], args)
      end

      private
      # Returns +[html_tag, html_options]+.
      def react_parse_options(options)
        # Syntactic sugar for specifying html tag.
        return [options, {:id => SecureRandom::hex}] if options.is_a?(Symbol)

        # Assign a random id if missing.
        options = options.reverse_merge(:id => SecureRandom::hex)

        # Use <div> by default.
        tag = options[:tag] || :div
        options.delete(:tag)

        [tag, options]
      end

      # Keep a module-level copy of the js VM. Note that we are depending on the underlying
      # VM to be threadsafe.
      def react_context
        @@react_context ||= begin
          react_code = File.read(::React::Source.bundled_path_for("react-with-addons.min.js"))
          components_code = ::Rails.application.assets['components.js'].to_s
          all_code = <<-CODE
            var global = global || this;
            #{react_code};
            React = global.React;
            #{components_code};
          CODE
          ExecJS.compile(all_code)
        end
      end

      def react_html(component, args={})
        # This works because even though renderComponentToString uses a callback API it is really synchronous
        jscode = <<-JS
          function() {
            var html = "";
            React.renderComponentToString(#{component}(#{args.to_json}), function(s){html = s});
            return html;
          }()
        JS
        react_context.eval(jscode).html_safe
      end

      def react_javascript_tag(component, mount_node_id, args={})
        <<-HTML.html_safe
          <script type='text/javascript'>
            React.renderComponent(#{component}(#{args.to_json}), document.getElementById("#{mount_node_id}"))
          </script>
        HTML
      end

    end
  end
end

ActionView::Base.class_eval do
  include ::React::Rails::ViewHelper
end

