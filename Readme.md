# Mooc Data Parser

Scripts made to process some data for our Massive Open Online Courses.

```bash
Usage: show-mooc-details.rb [options]
    -f, --force                      Reload data from server
    -u, --user username              Show details for user
    -m, --missing-points             Show missing compulsary points
    -c, --completion-precentige      Show completition percentige
    -e, --email emailaddress         Show details for user
    -t, --tmc-account tmc-account    Show details for user
    -l, --list                       Show the basic list
    -h, --help                       Show this message
```

Show basic info for applicants
```bash
./show-mooc-data.rb -l
```

Show basic info for applicants and percents for each week
```bash
./show-mooc-data.rb -l -c
```

Show basic info for applicants and missing points
```bash
./show-mooc-data.rb -l -m
```

Show basic info for applicants and percents for each week and missing points
```bash
./show-mooc-data.rb -l -c -m
```

Find info about a user
* by email:
```bash
./show-mooc-data.rb -e <email>
```

* by username:
```bash
./show-mooc-data.rb -u <username>
```

Flags `-c` and `-l` can be used with these too.
