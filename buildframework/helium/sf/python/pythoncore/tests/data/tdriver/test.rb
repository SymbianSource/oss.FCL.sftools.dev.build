# require needed Ruby, MATTI and Orbit files
require 'test/unit'
require 'otest/testcase'

    
  #TODO: Give suitable name for test class 
class TestClassName < Test::Unit::TestCase
    
    #no need to do anything for initialize method
  def initialize (args)
    super(args)
    # TODO define application name
    app_path("hbinputtest.exe")
  end 
  
  # Test case method
  #TODO: name test method with suitable name
  # Must: Test method must start test_
  # Recomended: really descriping name
  def test_do_something

  # create test object app from defined sut
    app = @sut.run(:name => @app_name)  
      sleep(10)
  
  #Application is closed after test
  app.close
  #Verifies it is closed
      
  end #End of test case test_do_something
 

end#Testsuite

