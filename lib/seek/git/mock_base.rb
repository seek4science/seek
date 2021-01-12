module Seek
  module Git
    # A class to mock git operations for testing
    class MockBase < Base
      def revparse(rev)
        super(rev)
      rescue ::Git::GitExecuteError
        'abcdef12345'
      end

      def fetch

      end

      # Some dummy refs/shas taken from the seek4science/seek repo
      def self.ls_remote(remote, ref = nil)
        {
            'head' => { :ref => 'HEAD', :sha => '068cecdfce022aa98532026957a0c9519402e156' },
            'branches' => { 'master' => { :ref => 'refs', :sha => '068cecdfce022aa98532026957a0c9519402e156' },
                            'workflow' => { :ref => 'refs', :sha => 'eae7837659ddb50a324e3afc7b38dba83155cc54' }
            },
            'tags' => { 'v1.10.0' => { :ref => 'refs', :sha => 'cc448436c3352c48e94e15e563c7639093e7f4ef' },
                        'v1.10.1' => { :ref => 'refs', :sha => '3d5c436f0004582f80bbd167cf399ec03a590cb0' },
                        'v1.10.2' => { :ref => 'refs', :sha => 'f1d7a18bd5a13f6a2adeb6d341ac85521cf73698' },
                        'v1.10.3' => { :ref => 'refs', :sha => '1f2498afd9f07156cdcc9e458d6c3bbdcedad3bf' }
            },
            'pull' => { '1/head' => { :ref => 'refs', :sha => '586ef7e7e04155596e56b9dd42e6fd1b0646333e' },
                        '11/head' => { :ref => 'refs', :sha => '471d39975deb8fb533eebf7845780ae5fec0af9f' }
            }
        }
      end
    end
  end
end