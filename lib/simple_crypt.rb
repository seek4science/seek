# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'yaml'
require 'openssl'
require 'digest/sha1'


module SimpleCrypt

  def encrypt object,key
    y=object.to_yaml

    c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    c.encrypt

    c.key = key
    e = c.update(y)
    e << c.final
    return e
  end

  def decrypt encryption,key

    c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    c.decrypt
    c.key = key    
    decrypted = c.update(encryption)
    decrypted << c.final

    YAML::load(decrypted)
  end

  def generate_key passcode
    Digest::SHA1.hexdigest(passcode)
  end

end
