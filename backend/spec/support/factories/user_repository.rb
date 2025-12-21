ID_PARAM_OF_USER ||= "userrrrrrrrrrrrrrr".freeze

def find_or_create_user
  ::User.find_by(id_param: ID_PARAM_OF_USER) || FactoryBot.create(:user)
end
