#PCS = policy, creator, submitter.
#FIX ME: Policy was removed from readAPI, then re-added elsewhere per request. check if it can be put back here.
class PCSSerializer < BaseSerializer

  has_many :creators
  has_many :submitter # set seems to be one way of doing optional

end
