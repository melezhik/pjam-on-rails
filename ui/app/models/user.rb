require 'role_model'
class User < ActiveRecord::Base
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
    devise :ldap_authenticatable, :trackable, :validatable, :rememberable

    validates :username, presence: true, uniqueness: true

    before_validation :get_ldap_email
    def get_ldap_email
        self.email = Devise::LDAP::Adapter.get_ldap_param(self.username,"mail").first
    end

    # use ldap uid as primary key
    before_validation :get_ldap_id
    def get_ldap_id
        self.id = Devise::LDAP::Adapter.get_ldap_param(self.username,"uidnumber").first
    end

include RoleModel

    roles :admin, :user
    roles_attribute :roles_mask  

end
