ICUI
====

ICUI is a user interface component for creating arbitrary [IceCube][ic] objects specifying arbitrary repetition of events. 

As a user interface component it is more oriented for interfaces that really need to excersize the complex scheduling capabilities of [IceCube][ic]. If you need a rather simple recurrence widget, [other projects](https://github.com/seejohnrun/ice_cube/wiki/Related-Projects) might provide a better experience.

Furthermore ICUI currently closely follows the logic of [IceCube][ic] itself, thus providing a strongly hierarchical way of constructing repetitions.

[ic]: (https://github.com/seejohnrun/ice_cube)

Usage
-----

ICUI constructs client side UI based on the JSON representation of a IceCube::Schedule object. Conventionally IceCube::Schedule are stored as YAML objects so using a function like this server-side might be helpful:

~~~ruby
require 'yaml'
require 'json'
def yaml2json(str)
  YAML::load(str).to_json
end
def json2yaml(str)
  JSON.parse(str).to_yaml
end
~~~

ICUI is dependant on jQuery and expects it to be already present. Typically ICUI will be used with a hidden form field which contains as it's value the JSON representation of the IceCube schedule. Then the jQuery method `icui` should be called to instantiate ICUI. The form field will be updated automatically with a new JSON representation on form submission.

For usage with AJAX the `icui.getData()` method must be called to get a native representation of the data.

~~~javascript
$(function() {
  var icui = $("input[type=hidden].icui").icui();
  // for ajax usage one must use 
  icui.getData();
  // to get the serialized data
  
  // ICUI does this automatically for you:
  $icuielem = $("input[type=hidden].icui");
  $icuielem.parent('form').on('submit', function() {
    $icuielem.val(JSON.stringify(icui.getData()));
  });
});
~~~

The `app.css` file contains some minimal styling namespaced to the `.icui` element, so it should be fine to include in your project, but further styling may be necessary to fit the look and feel of your application.

Gotcha's
--------

ICUI isn't tested on any IE, but should work, but might require a JSON shim. 

ICUI currently extends the `Date` prototype with a `strftime` (written by Gianni Chiappetta) method, the plan is to drop this in the future.

Currently ICUI doesn't support the rules and validations that have higher resolution than 1 day, however it should be fairly trivial to add these and in fact this is on the development roadmap.

ICUI currently deals with all times as if they are UTC times.

Development and Extension
-------------------------

The library is fairly easy to extend. It is written in OO CofeeScript. Extending usually involves subclassing the `Option` class and than modifying the parent class to create the instance of the child. For details see the [annotated source code](http://code.gampleman.eu/icui/docs/icui.html).
