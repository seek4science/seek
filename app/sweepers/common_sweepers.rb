# To change this template, choose Tools | Templates
# and open the template in the editor.

#includes some helper methods for commonly used fragament expirations
module CommonSweepers

  #expires ALL fragment caches related to favourites
  def expire_all_favourite_fragments
    expire_fragment(/\/favourites\/user\/.*/)
  end
    
end
