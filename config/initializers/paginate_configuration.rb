require 'settings'
class PaginateConfiguration
  #Settings.defaults[:index] = {:people => 'latest', :projects => 'latest', :institutions => 'latest', :investigations => 'latest',:studies => 'latest', :assays => 'latest',
   #                 :data_files => 'latest', :models => 'latest',:sops => 'latest', :publications => 'latest',:events => 'latest'}
  Settings.index = {:people => 'latest', :projects => 'latest', :institutions => 'latest', :investigations => 'latest',:studies => 'latest', :assays => 'latest',
                    :data_files => 'latest', :models => 'latest',:sops => 'latest', :publications => 'latest',:events => 'latest'}
end