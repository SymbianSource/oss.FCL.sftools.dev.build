from optparse import OptionParser

def main():
    parser = OptionParser(usage="%prog VERSION")
    opts, args = parser.parse_args()
    input = args[0]
    print input
    
main()