module Business::Base
  class Values
    include ActiveModel::Model
    include ActiveModel::Attributes

    def initialize(context_arg = nil, **params_arg)
      context, params = interpret_args(context_arg, params_arg)

      super(params)

      if context.present?
        raise_error unless valid?(context.to_sym)
      else
        raise_error unless valid?
      end
    end

    def [](attr)
      send(attr)
    end

    def []=(attr, value)
      send("#{attr}=", value)
    end

    private

    def raise_error(errors_obj: errors)
      raise errors_obj.full_messages.join(", and ")
    end

    def interpret_args(context_arg, params_arg)
      if context_arg.is_a?(Hash)
        params = context_arg.merge(params_arg)
        context = nil
      else
        params = params_arg
        context = context_arg
      end
      [context, params]
    end
  end
end
