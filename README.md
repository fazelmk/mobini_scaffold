# Mobini Scaffold

This gem is based on the Beautiful scaffold gem (https://github.com/rivsc/Beautiful-Scaffold)
And add extra functions to easly create bootstraped scaffold and nested models

## Installation

```
This gem is not yet released on https://rubygems.org/
so eather add by git or put it in your vendor director

gem 'mobini_scaffold', path => 'vendor/mobini_scaffold'

```

## Dependencies

  - Devise, Cancan and Rollify for permissions
  - nested_form for nesting models
  - paperclip for file and image
  - money-rails for monetary values

## Notes
  - If the attribute got 2 options or if it has a string. It must be between single quotes >> ' <<
  - If the model is in a namespace, the namespace has to go in the option "namespace"


## Custom Tipes

  - file
  - image
  - price
  - wday => will show day as text in index and show and combobox in form I18n.t('date.day_names')
  - date
  - datetime
  - time => uses time_mask class
  - phone => uses phone_mask class
  - enum => create new enum 'enumName:enum{enum:["opc1";"opc2";"opc3";"opc4"]}' OR use existing enum 'enumName:enum'
  - custom reference (Ex.: 'my_model_tag:references{class_name:namespace/model}')

## Usage

### SCAFFOLD (mks):
  mks command to generate the scaffold

```
  rails generate mks model myattributes

  argument :model, :type => :string, :desc => "Name of model"
  argument :myattributes, :type => :array, :default => [], :banner => "'field:type{option}' 'field:type{option}'"

  class_option :namespace, :default => nil create this model within the namespace
  class_option :without_import, :default => nil ```Replace gem files generated in project```
  class_option :without_export, :default => nil ```generate index without the export buttons```
  class_option :replace_shared, :default => nil ```generate index without the import button```
  class_option :without_locales, :default => nil ``` Don't create the needed file for I18n translation  ```
  class_option :admin_only, :default => nil ``` Makes it accessable only by users with admin role ```

  exp.:
    rails g mks Test 'name:string{limit:100,default:"test"}' has_test:boolean{default:true} test_index:integer{default:10}:index test_uniq:integer:uniq
```

## MIGRATION (mkm)
  mkm command generates the migrations

```
  rails generate mkm AddXxxToYyy myattributes

  argument :migration_name, :type => :string, :desc => "Name of the migration CamelCase AddXxxToYyy"
  argument :myattributes, :type => :array, :default => [], :banner => "field:type field:type (for bt relation model:references)"
  class_option :namespace, :default => nil

  exp.: rails g mks AddVisibleToTest visible:boolean
```

## Nested Form (mknf)
    mknf command creates a nested model to an existing models that where generates by mks

```
  rails generate mknf model parent_model myattributes

  argument :model, :type => :string, :desc => "Name of the new model Capitalized Xxxxx"
  argument :parent_model, :type => :string, :desc => "Name of the parent model"
  argument :myattributes, :type => :array, :default => [], :banner => "'field:type{option}' 'field:type{option}'"

  class_option :namespace, :default => nil
  class_option :replace_shared, :default => nil
  class_option :without_locales, :default => nil

  exp.: rails g mknf NestedChild ParentModel name:string visible:boolean
```

## New Join Table (mknjt)
  mknjt command creates a join table with the id of the two parent tables and the extra attributes and nest it in the two parents

```
  rails generate mknjt join_model_name model_1 model_2 myattributes

  argument :join_model_name, :type => :string, :desc => "Name of the join model"
  argument :model_1, :type => :string, :desc => "Name of the parent model with namespace (namespace/model)"
  argument :model_2, :type => :string, :desc => "Name of the child model with namespace (namespace/model)"
  argument :myattributes, :type => :array, :default => [], :banner => "'field:type{option}' 'field:type{option}'"

  class_option :namespace, :default => nil
  class_option :replace_shared, :default => nil
  class_option :without_locales, :default => nil
  class_option :nested_only_first_model, :default => nil


  #the model_one and model_two are in the namespace tested and the new model will be created in the namespace tested because of the --namespace option
  exp.:
  rails g mknjt model_one_join_model_two tested/model_one tested/model_two order:string --namespace=Tested
```

## Nest Existing Model (mknem)
  mknem command allows to nest an existing model to another existing model

```
  rails generate mknem parent_model nested_model

  argument :parent_model, :type => :string, :desc => "Name of the parent model with namespace (namespace/model)"
  argument :model_with_namespace, :type => :string, :desc => "Name of the child model with namespace (namespace/model)"

  exp.:
  rails g mknem tested/grand_child tested/grand_grand_child
```

## New Parent (mknp)
  mknp command adds a new parent to a nested model.  The main diference between mknp e mknem is that mknp is used for for models that are already nested and mknem is used to for models that are not (mknem will create the needed partials to nest the model and mknp will use existing ones)

```
  rails g mknp parent_model nested_model

  argument :parent_model, :type => :string, :desc => "Name of the parent model with namespace (namespace/model)"
  argument :model_with_namespace, :type => :string, :desc => "Name of the child model with namespace (namespace/model)"

  exp.:
  rails g mknp tested/child tested/nested_child
```

## TODO
 - Remove replace_shared Options and add rake task to do it
 - Document the custom types
