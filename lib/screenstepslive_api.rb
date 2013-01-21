require 'rubygems'
require 'active_resource'

module ScreenStepsLiveAPI
  class Error < StandardError; end
  class << self
    attr_accessor :user, :password, :host_format, :site_format, :domain_format, :protocol, :path
    attr_reader :account, :token
 
    # Sets the account name, and updates all the resources with the new domain.
    def account=(name)
      resources.each do |r|
        r.site = r.site_format % (host_format % [protocol, domain_format % name, r.path])
      end
      @account = name
    end
    
    def user=(value)
      resources.each do |r|
        r.user = value
      end
    end
    
    def password=(value)
      resources.each do |r|
        r.password = value
      end
    end
 
    def resources
      @resources ||= []
    end
    
    def setup
      settings = YAML.load_file("#{Rails.root}/config/sslive_api.yml").symbolize_keys
      self.account = settings[:account]
      self.user = settings[:user]
      self.password = settings[:password]
    end
  end
  
  self.host_format = '%s://%s/%s'
  self.domain_format = '%s.screenstepslive.com'
  self.protocol = 'https'
  
  class Base < ActiveResource::Base
    def self.inherited(base)
      ScreenStepsLiveAPI.resources << base
      class << base
        attr_accessor :site_format
        attr_accessor :path
      end
      base.site_format = '%s'
      super
    end
  end
  
  class Space < Base
    self.path = ''
    def manual(id_or_permalink)
      manual = Manual.find(id_or_permalink, :params => { :space_id => self.id })
      manual.space_id = self.id
      manual
    end
    
    def bucket(id_or_permalink)
      bucket = Bucket.find(id_or_permalink, :params => { :space_id => self.id })
      bucket.space_id = self.id
      bucket
    end
    
    def search(text, options = {})
      get('searches', {:text => text}.merge(options) )
    end
    
    def create_task(params)
      Task.create(params.merge(:space_id => self.id))
    end
    
    def lessons_for_tag(tag_name)
      get('tags', :tag => tag_name)
    end
  end
  
  class Manual < Base
    self.path = "spaces/:space_id"

    attr_accessor :space_id

    def lesson(id)
      lesson = Lesson.find(id, :params => { :space_id => space_id, :manual_id => self.id })
      lesson.space_id = self.space_id
      lesson.manual_id = self.id
      lesson
    end
    
    def search(text, options = {})
      get('searches', {:text => text}.merge(options) )
    end
    
    def lessons_for_tag(tag_name)
      get('tags', :tag => tag_name)
    end
  end
  
  class Lesson < Base
    attr_accessor :space_id, :manual_id
    self.path = "spaces/:space_id/manuals/:manual_id"
    
  end
  
end


__END__
 
require 'screenstepslive_api'
ScreenStepsLiveAPI.account = 'youraccount'
ScreenStepsLiveAPI.user = 'username'
ScreenStepsLiveAPI.password = 'your_password'
 
# this will only give you the id of the space, not its contents
 
s = ScreenStepsLiveAPI::Space.find(:first)
 
# now load the contents
 
s = ScreenStepsLiveAPI::Space.find(s.id)
 
# load the first manual
 
manual_id = s.manuals.first.id
m = s.manual(manual_id)
 
# load the first lesson. Lessons are in chapters in a manual.
 
lesson_id = m.chapters.first.lessons.first.id
l = m.lesson(lesson_id)
 
# if you already know the lesson_id, space_id and manual_id then you can do this:
 
l = ScreenStepsLiveAPI::Lesson.find(lesson_id, :params => {:space_id => space_id, :manual_id => manual_id})
 
# You would then want to iterate over the lesson contents using your own html tags. 
# Here are the attributes you would use
 
l.title
l.description
l.steps.each do |step|
  step.title
  step.instructions
  step.media.url
  step.media.width
  step.media.height
end
