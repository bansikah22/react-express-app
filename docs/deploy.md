Edit the /etc/hosts file and add this
```bash
localhost ip addr and frontend.local
localhost ip addr and backend.local

to test user 
curl http://frontend.local
curl http://backend.local/api/hello
```