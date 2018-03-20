# u2icc_plugins

You have to build a boat, then install and first run the atom editor. 

Make sure the APM is installed correctly by typing:

```shell
apm --version
```

## Usage:

```shell 
TEAM_TOKEN='winterns' CABLE_SERVER_URL='ws://localhost:3000/cable' ruby install_cc.rb install 
```
```shell 
ruby install_cc.rb run
```

## Installation:

1. Make sure Ruby is installed.
2. Make sure Docker is installed.
3. Go to the repo main folder check configuration in `install_cc.rb` (configure `Team_Token` and `CABLE_SERVER_URL` or specify correct environment variables in the next step).
4. Run `TEAM_TOKEN='winterns' CABLE_SERVER_URL='ws://localhost:3000/cable' ruby install_cc.rb install`.
5. Enjoy !

## Running:

1. `ruby install_cc.rb run`
