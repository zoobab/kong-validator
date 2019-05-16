# Kong-validator

A simple container to validate a kong.yml declarative config file, see examples here:

https://github.com/zoobab/kong-declarative-config

## Usage

```
$ mkdir -pv /tmp/1
$ vim /tmp/1/kong.yml
  _format_version: "1.1"
  services:
  - name: version
    url: http://localhost
    routes:
    - name: version
      paths:
      - /version
  - name: mocky24
    url: http://www.mocky.io/v2/5ca725833400002c4876b363
    routes:
    - name: mocky24
      paths:
      - /mocky24
$ cd /tmp/1
$ docker run -it -v /tmp/1:/mnt zoobab/kong-validator
parse successful
```

You can check the shell exit code as well (0 is success, 1 is failure):

```
$ docker run -it -v /tmp/1:/mnt zoobab/kong-validator
parse successful
$ echo $?
0
```

Now let's insert an error, replacing ```name:``` by ```name2:```:

```
$ docker run -it -v /tmp/1:/mnt zoobab/kong-validator
Error: Failed parsing:
in 'services':
  - in entry 1 of 'services':
    in 'routes':
      - in entry 1 of 'routes':
        in 'name2': unknown field

  Run with --v (verbose) or --vv (debug) for more details
$ 
```

You can check the shell exit code as well (0 is success, 1 is failure):

```
$ echo $?
1
```
