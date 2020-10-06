## Instructions

This is a limited functionality poky pipeline - it will grab the names
of recipes changed between origin/master and origin/master-next, and
build those as long as the recipe filename (once the version number has
been stripped) matches the actual recipe name.
