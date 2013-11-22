import urllib
import urllib2
import simplejson
import random
import string
import os

resultitem = 60
file_save_dir = 'images'
filename_length = 10
filename_charset = string.ascii_letters + string.digits
ipaddress = 'XXX.XX.XX.XXX'

while(resultitem < 500):
	url = ('https://ajax.googleapis.com/ajax/services/search/images?' +
	       'v=1.0&q=developers&rsz=8&userip='+ipaddress+'&start='+str(resultitem))
	request = urllib2.Request(url, None, {'Referer': 'http://www.google.com'})
	response = urllib2.urlopen(request)

	results = simplejson.load(response)
	for result in results['responseData']['results']:
		print result['unescapedUrl']
		filename = ''.join(random.choice(filename_charset)
	                   for s in range(filename_length))
		urllib.urlretrieve (result['unescapedUrl'], 
	                    os.path.join(file_save_dir, filename + '.png'))

	resultitem = resultitem + 8
