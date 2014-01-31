text = `hg summary`
$version = "0.7.0-#{text.match("parent:\s+(.+):")[1]}"
