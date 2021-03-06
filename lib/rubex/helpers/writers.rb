module Rubex
  module Helpers
    module Writers
      def declare_temps(code, scope)
        scope.temp_entries.each do |var|
          code.declare_variable type: var.type.to_s, c_name: var.c_name
        end
      end

      def declare_vars(code, scope)
        scope.var_entries.each do |var|
          if var.type.base_type.c_function?
            code.declare_func_ptr var: var
          else
            code.declare_variable type: var.type.to_s, c_name: var.c_name
          end
        end
      end

      def declare_carrays(code, scope)
        scope.carray_entries.select do |s|
          s.type.dimension.is_a? Rubex::AST::Expression::Literal::Base
        end.each do |arr|
          type = arr.type.type.to_s
          c_name = arr.c_name
          dimension = arr.type.dimension.c_code(@scope)
          value = arr.value.map { |a| a.c_code(@scope) } if arr.value
          code.declare_carray(type: type, c_name: c_name, dimension: dimension, value: value)
        end
      end

      def declare_types(code, type_entries)
        type_entries.each do |entry|
          type = entry.type

          if type.alias_type?
            base = type.old_type
            if base.respond_to?(:base_type) && base.base_type.c_function?
              func = base.base_type
              str = "typedef #{func.type} (#{type.old_type.ptr_level} #{type.new_type})"
              str << '(' + func.arg_list.map { |e| e.type.to_s }.join(',') + ')'
              str << ';'
              code << str
            else
              code << "typedef #{type.old_type} #{type.new_type};"
            end
          elsif type.struct_or_union? && !entry.extern?
            code << sue_header(entry)
            code.block(sue_footer(entry)) do
              declare_vars code, type.scope
              declare_carrays code, type.scope
              declare_ruby_objects code, type.scope
            end
          end
          code.nl
        end
      end

      def sue_header(entry)
        type = entry.type
        str = "#{type.kind} #{type.name}"
        str.prepend 'typedef ' unless entry.extern
        str
      end

      def sue_footer(entry)
        entry.extern ? ';' : " #{entry.type.c_name};"
      end

      def declare_ruby_objects(code, scope)
        scope.ruby_obj_entries.each do |var|
          code.declare_variable type: var.type.to_s, c_name: var.c_name
        end
      end

      def write_usability_macros(code)
        code.nl
        code.c_macro Rubex::RUBEX_PREFIX + 'INT2BOOL(arg) (arg ? Qtrue : Qfalse)'
        code.nl
      end

      def write_usability_functions_header(header)
        header.nl
        write_char_2_ruby_str_header header
      end

      def write_usability_functions_code(code)
        code.nl
        write_char_2_ruby_str_code(code)
      end

      def write_char_2_ruby_str_header(header)
        header.nl
        header << "VALUE #{Rubex::C_FUNC_CHAR2RUBYSTR}(char ch);"
      end

      def write_char_2_ruby_str_code(code)
        code << "VALUE #{Rubex::C_FUNC_CHAR2RUBYSTR}(char ch)"
        code.block do
          code << "char s[2];\n"
          code << "s[0] = ch;\n"
          code << "s[1] = '\\0';\n"
          code << "return rb_str_new2(s);\n"
        end
      end
    end
  end
end
