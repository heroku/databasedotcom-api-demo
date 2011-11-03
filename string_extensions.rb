# This extends String to add the +camelize+ method (the same method implementation 
# for upcase camelize in ActiveSupport::Inflector)
# http://as.rubyonrails.org/classes/ActiveSupport/Inflector.html#M000143
class String
  
  def camelize
    self.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
  end
  
end