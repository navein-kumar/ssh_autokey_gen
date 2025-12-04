```
./ssh_key_setup.sh
```
```
# Copy PEM file to local machine first
chmod 400 server_key_*.pem
ssh -i server_key_*.pem username@your_server_ip
```
