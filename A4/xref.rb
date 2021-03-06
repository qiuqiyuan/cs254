require 'set'
require 'fileutils'

def mkdir (dir_name)
  FileUtils.mkdir_p(dir_name) unless Dir.exist?(dir_name)
end

def is_interesting_filetype (path)
  /.*\.([ch]|dump)/.match(path)
end

def list_content(path)
  if File.file?(path)
    nil
  else
    Dir.glob(path)
  end
end

def list_files (path)
  res = []
  list_content(path).each do |child_path|
    res += if File.file?(child_path) && is_interesting_filetype(child_path)
             [child_path]
           else
             list_files(child_path + '/*')
           end
  end
  res
end

def get_tag_val (tag_name, str)
  m = /#{tag_name}<{1,2}([^>]*)>{1,2}/.match(str)
  m[1].to_s.gsub(/"/, '') if m
end

def get_project_root (dumpfile)
  res = Set.new
  File.open(dumpfile).each { |line|
    tag_val = get_tag_val('DW_AT_comp_dir', line)
    res.add(tag_val) if tag_val
  }
  raise '[ERROR] ' + dumpfile + ' size is not 1' unless res.size == 1
  # Give back the ONLY one element in set
  res.to_a[0].to_s
end

def get_main_url(dump_file)
  lines = File.readlines(dump_file)
  line = lines.find { |line| get_tag_val('DW_AT_name', line) == 'main' }
  if line
    './'+get_tag_val('DW_AT_decl_file', line).split[1] + '.html'
  else
  end
end

def get_file_lines (filename)
  File.foreach(filename) {}
  $.
end

def generate_dumpfile(binary_path)
  out_path = binary_path + '.dump'
  cmd = 'dwarfdump -dil ' + binary_path + ' >' + out_path
  %x(#{cmd})
  out_path
end


class DebugInfo

  def initialize(name='', comp_dir='', lines='')
    @type_name = 'DW_TAG_compile_unit'
    @name = name
    @comp_dir = comp_dir
    @idents = []
    @lines = lines
  end

  def name=(new_name)
    @name = new_name
  end

  def name
    @name
  end

  def comp_dir=(new_comp_dir)
    @comp_dir = new_comp_dir
  end

  def comp_dir
    @comp_dir
  end

  def idents
    @idents
  end

  def add(ident)
    @idents.push(ident)
  end

  def get_ident_type(line)
    line.split[0].gsub(/[<>]/, ' ').split[2]
  end

  def to_s
    [@name, @comp_dir, ('idents.size: ' + @idents.size.to_s), @idents].join("\n")
  end

end

class Ident
  def initialize(type_name = '', scope=-1, name='', src_path='', line_num=-1, id='')
    @type_name = type_name
    @scope = scope
    @name = name
    @src_path = src_path
    @line_num = Integer(line_num, 16)
    @id = id
  end

  def type_name
    @type_name
  end

  def scope
    @scope
  end

  def name
    @name
  end


  def src_path
    @src_path
  end

  def line_num
    @line_num
  end

  def id
    @id
  end

  def to_s
    [@name, @scope.to_s, @type_name,
     @src_path,
     @line_num, @id].join(', ')
  end

  def Ident.get_abs_path(path, comp_dir)
    if path[0] == '/'
      path
    else
      comp_dir + '/' + path
    end
  end
end

def get_src_path(tag, line, comp_dir)
  if get_tag_val(tag, line)
    path = get_tag_val(tag, line).split[1]
    Ident.get_abs_path(path, comp_dir)
  else
    nil
  end
end

def build_debug_info(lines)
  # lines is a list of line for identifiers
  # all lines has been checked to have the right format
  debuginfo = DebugInfo.new
  lines.each_with_index { |line, line_num|
    case debuginfo.get_ident_type(line)
      when 'DW_TAG_compile_unit'
        cnt_name = get_tag_val('DW_AT_name', line)
        cnt_comp_dir = get_tag_val('DW_AT_comp_dir', line)
        debuginfo.name=cnt_name
        debuginfo.comp_dir=cnt_comp_dir
      else
        cnt_type = debuginfo.get_ident_type(line)
        cnt_scope = get_tag_val('', line.split[0]).to_i
        cnt_name = get_tag_val('DW_AT_name', line)
        cnt_src_path = get_src_path('DW_AT_decl_file', line, debuginfo.comp_dir)
        cnt_line_num = get_tag_val('DW_AT_decl_line', line)
        cnt_id = debuginfo.name + '-' + line_num.to_s
        if cnt_type && cnt_scope && cnt_name && cnt_src_path && cnt_line_num && cnt_id
          cnt_ident = Ident.new(cnt_type, cnt_scope, cnt_name, cnt_src_path, cnt_line_num, cnt_id)
          debuginfo.add(cnt_ident)
        else

        end
    end
  }
  debuginfo
end


def build_debug_infos(dumpfile)
  lines = File.readlines(dumpfile)
  $i=0
  infos = {}
  info_lines = []
  while $i < lines.size
    cnt_line = lines[$i]
    if cnt_line.size == 0
      next
    elsif cnt_line[0] == "\n" && info_lines.size > 0
      info = build_debug_info(info_lines)
      infos[[info.comp_dir, info.name].join('/')] = info
      info_lines = []
    elsif cnt_line[0] == '<'
      info_lines.push(cnt_line)
    end
    $i = $i + 1
  end
  infos
end


class Scope
  def initialize(debug_infos={}, debug_lines={})
    @debug_infos = debug_infos
    @debug_lines = debug_lines
  end

  def find(ident_name, src_file, line_num)
    #ident_name: token name in src file
    #src_file; src_file path
    #line_num: line_num in src_file
    #return: a link the ident_name should attach to
  end
end

def build_scope(debug_infos, debug_lines)
  scope = Scope.new(debug_infos, debug_lines)
end

class DebugLine
  def initialize(src_file='', line_arr=[])
    @src_file = src_file
    @line_arr = line_arr
  end

  def add(entry)
    if entry.instance_of?(DebugLineEntry)
      @line_arr.push(entry)
    else
      raise('[Error] cannot add to DebugLine')
    end
  end

  def src_file
    @src_file
  end

  def src_file=(new_src_file)
    @src_file=new_src_file
  end

  def find_row(pc)
    #pc: program pointer in HEX
    #return: decimal number as line numbers
  end

  def to_s
    [@src_file, @line_arr.size, @line_arr].join("\n")
  end

end

class DebugLineEntry
  def initialize(pc=0, row=0, col=0, uri=nil)
    #pc is hex
    #row is decimal
    #cow is decimal
    #uri is src_file
    @pc = pc
    @row = row
    @col = col
    @src_file = uri
  end

  def to_s
    [@pc.to_s(16), @row, @col, @src_file||'nil'].join(', ')
  end

end

def build_debug_line(dline_entries)
  dl = DebugLine.new
  dline_entries.each_with_index { |line|
    # extract out hex, row and col number form entry
    pc, p_row_col = line[0..9], /\[.*\]/.match(line).to_s.gsub(/(\[|\]| )/, '').strip.split(',')
    if /uri/.match(line)
      uri = line.split[-1].gsub(/"/, '')
      entry = DebugLineEntry.new(pc.to_i(16), p_row_col[0].to_i, p_row_col[1].to_i, uri)
      dl.src_file=uri
      dl.add(entry)
    else
      entry = DebugLineEntry.new(pc.to_i(16), p_row_col[0].to_i, p_row_col[1].to_i)
      dl.add(entry)
    end
  }
  dl
end

def build_debug_lines(dumpfile)
  lines = File.readlines(dumpfile)
  $i=0
  dlines = {}
  dline_entries = []
  while $i < lines.size
    cnt_line = lines[$i]
    if cnt_line.size == 0
      next
    elsif cnt_line.start_with?('0x')
      dline_entries.push(cnt_line)
    elsif cnt_line.start_with?("\n") && dline_entries.size > 0
      dline = build_debug_line(dline_entries)
      dlines[dline.src_file] = dline
      dline_entries = []
    else
    end
    $i = $i + 1
  end
  dlines
end


def mk_index_file (index_file_path, list_files, main_url)
  mkdir(File.expand_path('..', index_file_path))
  File.open(index_file_path, 'w+') { |f|
    f.write("<!DOCTYPE HTML>\n")
    f.write("<BODY>\n")
    list_files.each { |file_name|
      url = '.' + file_name + '.html'
      f.write('<p>')
      f.write('<a href="' + url + '">' + file_name + '</a>')
      f.write("</p>\n")
    }
    # Add special link to main
    f.write('<p><a href="' + main_url + '">' + 'main' + '</a></p><br>')
    # Make time stamp
    f.write('Created Time: ' + File.mtime(f).to_s + '<br>')
    # File location
    f.write('Created WD: ' + Dir.getwd.to_s)
    f.write("</BODY>\n")
    f.write("</HTML>\n")
  }
end


def add_global_ident_tag(src_file_path, line_num, line, debuginfo)
  #print 'DEBUG: src_file_path: ',src_file_path ,' line_num: ' ,line_num, "\n"
  ident = debuginfo.idents.detect { |i| i.src_path == src_file_path && i.line_num == line_num }
  if ident
    line.gsub(/#{ident.name}/, '<a name = "' + ident.id + '" class = "' + ident.type_name + '">\0</a>')
  else
    #current line is not the definition line
    idents = debuginfo.idents.find_all {|i| i.scope == 1 && line.include?(i.name)}
    if idents
      for ident in idents
        line = line.gsub(/#{ident.name}/, '<a href = "#' + ident.id + '">\0</a>')
      end
      line
    else
      line
    end
  end
end

def mk_html_pages(old_root, new_root, debuginfos)
  list_content(old_root).each { |child_path|
    if File.file?(child_path) && is_interesting_filetype(child_path)
      #make sure parent dir exists
      mkdir(new_root + '/' + File.expand_path('..', child_path))
      File.open(new_root + child_path + '.html', 'w+') { |html_f|
        n_child_path = get_file_lines(child_path)
        File.open(child_path, 'r') { |orig_f|
          html_f.write("<!DOCTYPE HTML>\n")
          html_f.write("<BODY>\n")
          html_f.write("<code>\n")
          #start decorating each line in orig_f
          File.foreach(orig_f).with_index { |line, line_num|
            # order of these replacement matters
            # amp should go first
            line = line.gsub(/&/, '&#38;')
            line = line.gsub(/</, '&#60;')
            line = line.gsub(/>/, '&#62;')
            line = line.gsub(/ /, '&#160;')

            if (dinfo = debuginfos[orig_f.path])
              line = add_global_ident_tag(child_path, line_num + 1, line, dinfo)
            end


            line = (line_num + 1).to_s.ljust(n_child_path.to_s.length, ' ') + ' ' + line
            html_f.write(line + "<br>\n")
          }
          html_f.write("</code>\n")
          html_f.write("</BODY>\n")
          html_f.write("</HTML>\n")
        }
      }
    else
      mk_html_pages(child_path + '/*', new_root, debuginfos)
    end
  }
end


def main
  dumpfile_path = generate_dumpfile(ARGV[0].to_s)
  p_root = get_project_root(dumpfile_path)
  puts p_root
  debug_infos= build_debug_infos(dumpfile_path)
  #print stuff out
  debug_infos.values.each { |dinfo|
    puts dinfo.to_s
    puts
  }
  debug_lines = build_debug_lines(dumpfile_path)
  # debug_lines.values.each { |dline|
  #   puts dline.to_s
  #   puts
  # }

  mk_html_pages(p_root, './HTML', debug_infos)
  mk_index_file('./HTML/index.html', list_files(p_root), get_main_url(dumpfile_path))
end

if __FILE__ == $0
  main
end
