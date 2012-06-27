class User < ActiveRecord::Base
  has_many :authentications
  
  EMAIL_REGEX = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i
  
  validates :firstname, :presence => true, :length => { :maximum => 25 }
  validates :lastname,  :presence => true, :length => { :maximum => 50 }
  validates :email, :presence => true, :length => { :maximum => 100 }, :format => EMAIL_REGEX
  # validates :password, :presence => true, :confirmation => true,:length => {:within => 8..25}
		         
  validate :sex_validation_method
  validates_date  :birthday

 def sex_validation_method
   if self.sex == ''
     errors.add(:sex, "type is required")
     return false
   end
 end
 
  def apply_omniauth(omniauth_hash)
    
    if (omniauth_hash["provider"] == ("facebook"))
       self.email      = omniauth_hash['info']['email'] if email.blank?
       self.firstname  = omniauth_hash['info']['first_name'] if firstname.blank?
       self.lastname   = omniauth_hash['info']['last_name'] if lastname.blank?
       if (omniauth_hash['extra']['raw_info']['gender'].downcase.eql?("male"))
         self.sex = '1'
       else 
         self.sex = '0'
       end
       self.birthday = Date.strptime(omniauth_hash['extra']['raw_info']['birthday'],'%m/%d/%Y')
    else
       fullname = omniauth_hash['info']['name'].to_s.split(" ")
       if !fullname[0].nil? 
         self.firstname = fullname[0]
       end
       if !fullname[1].nil?
         self.lastname = fullname[1]
       end
    end
    authentications.build(:provider => omniauth_hash['provider'], :uid => omniauth_hash['uid'])      
  end
  
  def password_required?
    (authentications.empty? || !password.blank?) && super
  end

  def update_with_password(params={})
    current_password = params.delete(:current_password) if !params[:current_password].blank?
  
    if params[:password].blank?
      params.delete(:password)
      params.delete(:password_confirmation) if params[:password_confirmation].blank?
    end
  
    result = if has_no_password?  || valid_password?(current_password)
      update_attributes(params) 
    else
      self.errors.add(:current_password, current_password.blank? ? :blank : :invalid)
      self.attributes = params
      false
    end
  
    clean_up_passwords
    result
  end

  def has_no_password?
    self.encrypted_password.blank?
  end
  
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible  :current_password,:email, :password, :password_confirmation, :remember_me, :firstname, :lastname, :sex, :birthday
  attr_accessor  :current_password 
end
