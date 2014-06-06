class API::V1::Endpoints::Admin::Accounts < Grape::API
  include API::V1::Defaults

  resource 'admin/accounts' do
    helpers API::V1::Params::Admin::Account
    helpers API::V1::Helpers::Shared
    helpers API::V1::Params::Shared
    helpers do
      def model
        @model ||= ::Admin::Account
      end

      def entity
        @entity ||= API::V1::Entities::Admin::Account
      end
    end

    namespace do
      params do
        use :login
      end
      post :login do
        return if session[:user_type]

        login = safe_params[:login]
        user  = model.login(login[:username], login[:password])

        if user
          session[:user_id] = user.id
          session[:user_type] = Loginable::AdminRole
        else
          error!('401', 401)
        end
      end
    end

    namespace do
      before do
        authenticate!
      end

      get do
        present model.all, with: entity
      end

      desc 'Create an admin'
      params do
        use :admin_create
      end
      post do
        present model.create!(safe_params[:admin_account]), with: entity
      end

      desc 'Log out an admin'
      delete :logout do
        session.delete :user_type
        session.delete :user_id
      end

      route_param :id, type: Integer, desc: 'admin id' do
        before do
          @record = model.find(params[:id])
        end

        desc 'Get an admin by id'
        get do
          present @record, with: entity
        end

        desc 'Update an admin by id'
        params do
          use :admin_update
        end
        put do
          @record.update! safe_params[:admin_account]
          present @record, with: entity
        end

        desc 'Delete an admin by id'
        delete do
          present @record.destroy, with: entity
        end
      end
    end
  end
end
