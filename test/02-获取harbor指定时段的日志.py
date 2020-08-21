# pylint: disable=no-member
# -*- encoding: utf-8 -*-
'''
@File    :   02-获取指定时段的日志.py
@Time    :   2020/08/21 12:44:07
@Author  :   Kellan Fan 
@Version :   1.0
@Contact :   kellanfan1989@gmail.com
@Desc    :   None
'''

# here put the import lib
import sys
import json
import urllib3
import requests
import datetime
urllib3.disable_warnings()

class HarborApi(object):
    def __init__(self, url, username, passwd, protocol="https"):
        '''
        init the request
        :param url: url address or doma
        :param username:
        :param passwd:
        :param protect:
        '''
        self.url = url
        self.username = username
        self.passwd =passwd
        self.protocol = protocol
        

    def login_get_session_id(self):
        '''
        by the login api to get the session of id
        :return:
        '''
        harbor_version_url = "%s://%s/api/systeminfo"%(self.protocol, self.url)
        header_dict = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:64.0) Gecko/20100101 Firefox/64.0', \
            'Content-Type': 'application/x-www-form-urlencoded'
        }
        data_dict = {
            "principal": self.username,
            "password": self.passwd
        }
        v_req_handle = requests.get(harbor_version_url, verify=False)
        self.harbor_version = v_req_handle.json()["harbor_version"]
        if self.harbor_version.startswith("v1.4"):
            req_url = "%s://%s/login" % (self.protocol, self.url)
            self.session_id_key = 'beegosessionID'
        elif self.harbor_version.startswith("v1.7"):
            req_url = "%s://%s/c/login" % (self.protocol, self.url)
            self.session_id_key = "sid"
        else:
            raise ConnectionError("the %s version is not to supply!"%self.harbor_version)
        req_handle = requests.post(req_url, data=data_dict, headers=header_dict, verify=False)
        if 200 == req_handle.status_code:
            self.session_id = req_handle.cookies.get(self.session_id_key)
            return self.session_id
        else:
            raise Exception("login error,please check your account info!"+ self.harbor_version)


    def logout(self):
        requests.get('%s://%s/logout' %(self.protocol, self.url),
                     cookies={self.session_id_key: self.session_id})
        raise Exception("successfully logout")

    def project_info(self):
        project_url = "%s://%s/api/projects" %(self.protocol, self.url)
        req_handle = requests.get(project_url, cookies={self.session_id_key: self.session_id}, verify=False)
        if 200 == req_handle.status_code:
            return req_handle.json()
        else:
            raise Exception("Failed to get the project info。")

    def logs_info(self, page, page_size=240):
        logs_url = '%s://%s/api/logs?page=%d&page_size=%d' %(self.protocol, self.url, page, page_size)
        req_handle = requests.get(logs_url, cookies={self.session_id_key: self.session_id}, verify=False)
        if 200 == req_handle.status_code:
            return req_handle.json()
        else:
            raise Exception("Failed to get the logs info。")

def com_time(time1, time2):
    d1 = datetime.datetime.strptime(time1,'%Y-%m-%d %H:%M:%S')
    d2 = datetime.datetime.strptime(time2,'%Y-%m-%d %H:%M:%S')
    if d1 >= d2:
        return True
    else:
        return False

def main(argv):
    client = HarborApi('192.168.1.20','admin','Harbor12345',protocol='http')
    client.login_get_session_id()
    page = 1
    file_name = 'harbor.log'
    request_start_time = argv[1]
    request_end_time = argv[2]
    while True:
        try:
            ret = client.logs_info(page)
            if ret:
                for item in ret:
                    current_time = str(item['op_time'].split('T')[0]) + ' ' + str(item['op_time'].split('T')[1].split('.')[0])
                    print(current_time)
                    if com_time(request_end_time, current_time) and com_time(current_time, request_start_time):
                        print(item)
                        with open(file_name, 'a+') as f:
                        	json.dump(item, f)
                        	f.write('\n')
            else:
                break
        except Exception as e:
            print('ERROR: {}'.format(e))
            break
        else:
            page += 1
if __name__ == "__main__":
	if len(sys.argv) != 3:
		print("{} <start_time> <end_time>".format(sys.argv[0]))
		print("Example: {} '2020-08-20 08:00:00' '2020-08-21 08:00:00'".format(sys.argv[0]))
		sys.exit()
	main(sys.argv)