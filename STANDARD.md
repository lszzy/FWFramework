# FWFramework

# [中文](STANDARD_CN.md)

## Coding Standards
### Naming
* The principle of precedence by convention, if there is a naming convention, the convention should be followed first, example:

		FWClassName.sharedInstance

* The framework custom OC class must start with FW and be named in camel case. Example:

		FWClassName

* The frame enumeration must start with FW, and the enumeration item must start with the enumeration type; the application enumeration item can start with k+enumeration type, with camel case naming, example:

		# Framework
		FWLogType
		FWLogTypeVerbose
		# Application
		AppEnumType
		kAppEnumTypeValue
	
* The framework custom protocol and proxy must start with FW and end with Protocol/Delegate/DataSource, with camel case naming, example:

		FWTestProtocol
		FWViewDelegate
		FWTableViewDataSource
		
* Framework custom OC methods, classification methods, and attributes must start with fw and be named in camel case to distinguish them from system methods. Examples:

		fwCGRectAdd
		fwMethodName
		fwPropertyName

* The class initialization method of the framework OC classification must start with fw, example:

		 fwColorWithString
		 fwImageWithView

* Frame C methods must start with fw\_, internal c methods must start with fw\_inner\_, internal c global static variables must start with fw\_static\_, separated by underscores, examples:

		fw_method_name
		fw_inner_method
		fw_static_variable
		
* Framework custom protocol methods, custom class methods, and attributes do not need to start with fw, examples:

		FWTestProtocol.methodName
		FWClassName.methodName
		FWClassName.initWithString

* The internal OC class of the framework must start with FWInner, the internal OC method must start with fwInner, and the internal OC global static variables must start with fwStatic, named in camel case. Example:

		FWInnerClassName
		fwInnerDebug
		fwStaticVariable

* The internal global attributes of the framework class uniformly use _ as a suffix to distinguish them from external attributes. Example:

		propertyName_

* The internal extension header file of the framework class must be named in the format of class name+Private.h (using the extension declaration, the main file implementation), the internal class classification of the framework uses the Private classification naming, example:

		FWClassName+Private.h
		FWClassName(Private)

### Macro
* The principle of precedence by convention, if there is a naming convention, the convention should be followed first, and ifndef must be added for judgment.

		// use
		@weakify
		
		// definition
		#ifndef weakify
		#define weakify( x ) \
			...
		#endif

* Frame compilation macro definition constants must start with FW_, all capitals, separated by underscores, example:
	
		FW_TEST

* The frame OC macro definition or macro definition method must start with FW, and the realization of the macro definition must start with FWDef, with camel case naming. Example:
	
		FWScreenSize
		FWPropertyStrong
		FWDefPropertyStrong
		
* The frame C macro definition must start with fw_, separated by underscores, examples:

		fw_macro_make
	
* Internal macro definitions uniformly use _ as a suffix to distinguish them from public macro definitions. Examples:

		fw_macro_first_
		FWIsScreenInch_

### Comment
* xcode comments, class files should be pragma segmented according to function modules, unfinished functions should be marked with TODO, etc. Common comments are as follows:

		// OC version notes
		#pragma mark - Lifecycle
		#pragma mark - Accessor
		#pragma mark - Public
		#pragma mark - Private
		#pragma mark - UITableViewDataSource
		#pragma mark - UITextViewDelegate
		// TODO: feature
		// FIXME: hotfix
		
		// Swift version notes
		// MARK: - Lifecycle
		// MARK: - Accessor
		// MARK: - Public
		// MARK: - Private
		// MARK: - UITableViewDataSource
		// MARK: - UITextViewDelegate
		// TODO: feature
		// FIXME: hotfix
		
* Code comments, using the HeaderDoc standard, [list of available tags](https://developer.apple.com/legacy/library/documentation/DeveloperTools/Conceptual/HeaderDoc/tags/tags.html), common comments are as follows:

		// Comment format
		/*!
 		 @brief tag description
		 @discussion detailed description
		 @... ...
 		 */
 		
 		// Generic label
		@brief Brief description
		@abstract Brief description, similar to brief
		@discussion detailed description
		@internal mark internal documents, enable --document-internal to take effect
		@see link tag
		@link link tag, similar to see, @/link ends
		@updated update date

		// File label
		@header file name, Top-level (optional, automatically generated)
		@file file name, Top-level, same as header
		@indexgroup document grouping
		@author Author
		@copyright copyright
		@ignore ignore the specified keyword document
		@version version number

		// class, interface, protocol label
		@class class name, Top-level
		@interface class name, same as class, Top-level
		@protocol agreement, Top-level
		@category category name, Top-level
		@classdesign class design description, support multiple lines
		@deprecated Deprecated description
		@superclass superclass

		// method label
		@function C method name, Top-level
		@method OC method name, Top-level
		@param parameter name description
		@return return description
		@throws throws an exception

		// Variable label
		@var instance variable description, used for global variables, attributes, etc., Top-level
		@const Constant name, Top-level. Non-Top-level during enumeration
		@constant Constant name, same as const, Top-level. Non-Top-level during enumeration
		@property OC attribute, Top-level
		@enum enumeration, Top-level
		@struct structure, Top-level
		@typedef definition, Top-level
		@field name description
		
		// C preprocessing macro tag
		@define macro name, #define, Top-level
		@defined macro name, Top-level
		@defineblock continuous macro definition, @/defineblock ends, Top-level
		@definedblock continuous macro definition, @/definedblock ends, Top-level
		@define name description, it means a single definition when used for continuous macro definition
		@param parameter name description
		@parseOnly mark hidden in the document

		// CodeSnippets placeholder
		<#abstract#>: placeholder
 		
 		// xctempleate system macro
		___FILENAME___: File name
		___PROJECTNAME___: Project name
		___FULLUSERNAME___: username
		___COPYRIGHT___: Copyright statement
		___DATE___: Date
