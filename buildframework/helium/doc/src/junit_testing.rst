.. index::
  module: Testing using JUnit

####################
Testing using JUnit
####################


.. contents::

.. index::
  single: JUnit - what is it

What is JUnit
=============
JUnit is a simple open source Java testing framework used to write and run repeatable automated tests. It is an 
instance of the xUnit architecture for unit testing framework. Eclipse supports creating test cases and running 
test suites, so it is easy to use for your Java applications.

.. index::
  single: JUnit features include

JUnit features include:
-----------------------
    * Assertions for testing expected results
    * Test fixtures for sharing common test data
    * Test suites for easily organizing and running tests
    * Graphical and textual test runners

.. index::
  single: JUnit Coding Convention

JUnit Coding Convention:
------------------------
    * Name of the test class must end with "Test".
    * Name of the method must begin with "test".
    * Return type of a test method must be void.
    * Test method must not throw any exception.
    * Test method must not have any parameter.

.. index::
  single: JUnit write and run simple test

How you write and run a simple test
===================================
    Lets think about we need to test the following Calculator Class 

    public class Calculator
    {
        
        int sum(int num1,int num2){
        
            return num1+num2;          
            
        }   
             
    }
        
1. Import JUnit Class.
----------------------

(The assumption for this code using junit v 4.4 )

import junit.framework.*;

Since we are using some constructs created by the makers of JUnit we must import any of the classes we desire to use, most of these reside in the framework subdirectory, hence the import statement.   


2. Create a subclass of TestCase:
----------------------------------

public class CalculatorTest extends  TestCase {
  
  Calculator cal=new Calculator();
  
}

Our simple class needs to define its own test method(s) to actually be of any use so it extends TestCase which provides us with the ability to define our own test methods

3. Write a test method to assert expected results on the object under test:
---------------------------------------------------------------------------
public void  testSum() {
  
     assertEquals(2,cal.sum(1,1));
     
}

4. Code location:
-----------------
Place the test class under "\helium\tools\common\java\test"



5. Execute the test by the command
----------------------------------

    hlm ju-unittest



.. index::
  single: JUnit report

JUnit report 
============

There are few ways to check the report 

1. At console
-------------

The test result appears in the console as below (after execute the command : hlm ju-unittest)

    [cobertura-report] Cobertura GNU GPL License (NO WARRANTY) - See COPYRIGHT file

    [cobertura-report] Cobertura: Loaded information on 14 classes.

    [cobertura-report]

    [cobertura-report] Average line coverage : 19.00%

    [cobertura-report] Average branch coverage : 15.00%

    [cobertura-report]

    [cobertura-report] class-name=nokia.ant.AntConfiguration line-rate=00.00% branch-rate=00.00%

    [cobertura-report] class-name=nokia.ant.AntLint line-rate=00.00% branch-rate=00.00%
    
    [cobertura-report] class-name=nokia.ant.ScanLogParser line-rate=00.00% branch-rate0.00%

    [cobertura-report] class-name=nokia.ant.XMLHandler line-rate=66.23% branch-rate=45.00%


2. At Buildbot
--------------
For a regular build the result appear in buildbot as follows 

    [cobertura-report] Cobertura GNU GPL License (NO WARRANTY) - See COPYRIGHT file

    [cobertura-report] Cobertura: Loaded information on 14 classes.

    [ccobertura-report] 

    [cobertura-report] Average line coverage : 15.56%

    [cobertura-report] Average branch coverage : 06.96%

    [cobertura-report] 

    [cobertura-report] class-name=nokia.ant.AntConfiguration line-rate=00.00% branch-rate=00.00%

    [cobertura-report] class-name=nokia.ant.AntLint line-rate=00.00% branch-rate=00.00%

    [cobertura-report] class-name=nokia.ant.AntLint$AntLintHandler line-rate=00.00% branch-rate=00.00%

    [cobertura-report] class-name=nokia.ant.BuildData line-rate=59.49% branch-rate=20.00%

    [cobertura-report] class-name=nokia.ant.BuildData$BuildFault line-rate=100.00% branch-rate=100.00%

    [cobertura-report] class-name=nokia.ant.BuildData$StageData line-rate=00.00% branch-rate=00.00%

    [cobertura-report] class-name=nokia.ant.Retry line-rate=00.00% branch-rate=00.00%

    [cobertura-report] class-name=nokia.ant.ScanLogParser line-rate=00.00% branch-rate=00.00%

    [cobertura-report] class-name=nokia.ant.XMLHandler line-rate=66.23% branch-rate=45.00%

    [cobertura-report] Report time: 640ms



3. Report folder 
----------------

If you need to generate a html report then please uncomment the below line from build.xml and check the report from ${line.coverage.reports} properties location

<!-- <cobertura-report  format="html" destdir="${line.coverage.reports}" srcdir="${src.classes}" datafile="../cobertura.ser" /> -->

    
            
.. index::
  single: JUnit execute multiple test cases

Execute multiple test cases with TestSuite
==========================================

If you have two tests and you'll run them together you could run the tests one at a time yourself, but you would quickly grow tired of that. Instead, JUnit provides an object TestSuite which runs any number of test cases together. The suite method is like a main method that is specialized to run tests.

Create a suite and add each test case you want to execute:

    public static void suite(){
    
        TestSuite suite = new TestSuite();
        
            suite.addTest(new CalculatorTest ("testSum"));
            
            ****************************************;
                        
            ****************************************;
                              
            ****************************************;
                        
        return suite;   
                
    }   
      

Since JUnit 2.0 there is an even simpler way to create a test suite, which holds all testXXX() methods. 
You only pass the class with the tests to a TestSuite and it extracts the test methods automatically.
    

.. index::
  single: JUnit Assert

JUnit Assert
============

.. csv-table::   
   :header: "Assert Name"

   "``assertEquals(expected, actual)``"
   "``assertEquals(message, expected, actual)``"
   "``assertEquals(expected, actual, delta)``"
   "``assertEquals(message, expected, actual, delta)``" 
   "``assertFalse(condition)``"
   "``assertFalse(message, condition)``"
   "``Assert(Not)Null(object)``"
   "``Assert(Not)Null(message, object)``"
   "``Assert(Not)Same(expected, actual)``"
   "``Assert(Not)Same(message, expected, actual)``"
   "``assertTrue(condition)``"
   "``assertTrue(message, condition)``"


.. index::
  single: JUnit References

References
==========
http://www.junit.org/

http://junit.sourceforge.net/doc/cookstour/cookstour.htm

    