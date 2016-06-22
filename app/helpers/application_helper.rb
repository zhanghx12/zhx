# -*- encoding : utf-8 -*-
module ApplicationHelper
  # 网页title
  def title(page_title)
    content_for :title, page_title.to_s + " - #{Setting.site_name}"
  end

  # 加载css: <%= stylesheets 'my1','my2' %>
  def stylesheets(*args)
    stylesheet_link_tag(*args)
  end

  # 加载js: <%= javascripts 'my1','my2' %>
  def javascripts(*args)
    javascript_include_tag(*args)
  end

  def umeditor
    um_pre_path = '/plugins/umeditor'
    stylesheets("#{um_pre_path}/themes/default/css/umeditor.css") + 
    javascripts("#{um_pre_path}/umeditor.config.js", "#{um_pre_path}/umeditor.min.js", "#{um_pre_path}/lang/zh-cn/zh-cn.js")
  end

  def my97
    javascripts "/plugins/my97/WdatePicker.js"
  end

  # 列表显示序号
  def index_no(index, per = 20)
    params[:page] ||= 1
    (params[:page].to_i - 1) * per + index + 1
  end

  def col_hint(text = '')
    "<i class='icon-info-sign art_tip_hover'></i>
      <span class='hide'>#{text}</span>".html_safe
  end

  # 消息类型中文
  def flash_status_chn(status)
    case status.to_sym
    when :error
      "操作失败！"
    when :success
      "操作成功！"
    else
      "温馨提示："
    end
  end

  # 日志
  def log_rs(doc, node = 'log')
    begin
      Nokogiri::XML(doc).xpath("//#{node}")
    rescue Exception => e
      []
    end
  end

  def english_num(num)
    num_hash = {"1" => "one", "2" => "two", "3" => "three", "4" => "four", "5" => "five", "6" => "six", "7" => "seven", "8" => "eight", "9" => "nine", "10" => "ten", "11" => "eleven", "12" => "twelve", "13" => "thirteen", "14" => "fourteen", "15" => "fifteen", "16" => "sixteen", "17" => "seventeen", "18" => "eighteen", "19" => "nineteen", "20" => "twenty"}
    num_hash[num]
  end

  # 连接新窗口打开
  def link_to_blank(*args, &block)
    if block_given?
      options      = args.first || {}
      html_options = args.second || {}
      link_to_blank(capture(&block), options, html_options)
    else
      name         = args[0]
      options      = args[1] || {}
      html_options = args[2] || {}

      # override
      html_options.reverse_merge! target: '_blank'

      link_to(name, options, html_options)
    end
  end

  # 连接为js
  def link_to_void(*args, &block)
    link_to(*args.insert((block_given? ? 0 : 1), "javascript:void(0)"), &block)
  end

  def link_to_back(opts = {}, html_opts = {})
    opts[:title] ||= '返回'
    link_to_btn title: opts[:title], size: 'btn-small', url: opts[:url]
  end

  def link_to_btn(opts = {}, html_opts = {})
    title = opts[:title] || 'title'
    size = opts[:size] || 'btn-big'
    btn_style = opts[:btn_style] || ''
    style = {class: "btn btn-#{btn_style} ml5 " + size}.merge(html_opts)
    return link_to title, opts[:url], style if opts[:url]
    # link_to_function(title, 'history.go(-1)', style)
  end

  # 弹出dialog提示
  def link_to_dialog(title, text, options = {})
    link = link_to_void(title, class: "d-tip")
    div = content_tag :div, text, class: 'd-tip-content hide'
    (link + div).html_safe
  end

  # 必须项，红星
  def require_span
    "<span class='red'>* </span>".html_safe
  end

  #  无限级联下拉框 搭配js
  # <%= dynamic_selects Area.provinces, nil %>
  def dynamic_selects(roots, value_id, aim_id = nil, options = {})
    data_class = roots.is_a?(Class) ? roots : roots.first.class
    options[:include_blank] ||= "请选择"
    # options.merge!({:class => 'multi-level', :otype => data_class.to_s, :aim_id => aim_id })
    options = {:class => 'multi-level', :otype => data_class.to_s, :aim_id => aim_id }.merge!(options)
    if options[:reject_ids]
      roots = roots.delete_if{|root| options[:reject_ids].include?(root.id)}
      options.merge!({:reject_ids => options[:reject_ids].join(",") })
    end
    value_object = data_class.find_by_id(value_id)
    select_text = value_object.try(:has_children?) ? collection_select('value_object-parent-id', 0, value_object.children, :id, :name, {:selected => value_object.try(:id), :include_blank => options[:include_blank]}, options) : ''
    aim_id = aim_id.to_s
    while value_object && value_object.parent && value_object.ancestry_depth > roots.first.ancestry_depth
      select_text = collection_select('value_object-parent-id', value_object.id, value_object.parent.children, :id, :name, {:selected => value_object.try(:id), :include_blank => options[:include_blank]}, options) << select_text
      value_object = value_object.parent
    end

    select_text = collection_select('value_object-parent-id', 0, roots, :id, :name, {:selected => value_object.try(:id), :include_blank => options[:include_blank]}, options) << select_text
    raw select_text
  end

  # 按钮下拉方式展示
  def operate_buttons(object, options = {}, &block)
    return "" if object.blank?
    lis = ""
    if object.is_a?(Array)
      if object.size == 1
        return object[0].gsub("<a", "<a class='btn btn-primary btn-small'").html_safe
      end
      lis = object.map{|link| "<li>#{link}</li>" }.join("")
    elsif object.present?
      options[:namespace] = "ancient" if options[:namespace].nil?
      namespace = options[:namespace]
      links = []
      edit_path = eval("#{['edit', namespace, object.class.to_s.tableize.singularize, 'path'].compact.join('_')}(#{object.id},:back => request.fullpath)")
      destroy_path = eval("#{[namespace, object.class.to_s.tableize.singularize, 'path'].compact.join('_')}(#{object.id},:back => request.fullpath)")

      links << link_to('修改', edit_path)
      links << link_to('删除', destroy_path, :method => 'delete', :confirm =>'您确定吗？')
      links += options[:links] if options[:links].present?
      lis = links.map{|link| "<li>#{link}</li>" }.join("")
      if block_given?
        lis << capture(&block)
      end
    end
    html = %Q|
      <div class="btn-group">
        <button class="btn btn-primary btn-small dropdown-toggle" data-toggle="dropdown">操作<span class="caret"></span></button>
        <ul class="dropdown-menu #{options[:ul_class]}">
          #{lis}
        </ul>
      </div>
    |.html_safe
  end

  # 温馨提示
  def tips(*args)
    content_tag(:div, :class => "alert alert-info", style: "position: static;") do
      content_tag(:h5, "说明：", :class => "alert-heading") <<
        content_tag(:ul) do
          args.map{|arg| concat content_tag(:li, arg) }
        end
    end
  end

  # 显示为：xx小时以前
  def time_ago_in_words(from_time, include_seconds = false)
    "#{super from_time, include_seconds: include_seconds}前"
  end

  # 文字加一个背景
  def label_tag(text, style = 'info', options = {})
    "<label title='#{options[:title]}' style='#{options[:style]}' id='#{options[:id]}' class='label label-#{style}'>#{text}</label>".html_safe
  end

  # 问号，提示内容
  def wenhao(text)
    (image_tag("dota/w2.jpg", width: '16px', height: '16px', class: "wenhao") + 
    "<span class='hide'>#{text}</span>".html_safe).html_safe
  end

  # ztree+art_dialog的下拉选择框
  def art_select(to_id, values, url, options = {})
    clas = options[:class].to_s + ' drop_select'
    options.merge!({:class => clas, :readonly => "readonly", :dropdata => url})
    options[:droplimit] ||= "0"
    options[:droptree] ||= "true"
    options[:input_name] ||= to_id
    input_id = to_id.gsub('[', "_").gsub(']', '_')
    if values.blank?
      name_value = id_value = ""
    # elsif [Array, ActiveRecord::Relation].include?(values.class)
    elsif values.respond_to?(:first) && !values.is_a?(String)
      name_value = values.map(&:name).join(", ")
      # name_value = values.map(&:name).join(",") if values.map(&:depth).uniq.size == 1
      id_value = values.map(&:id).join(",")
    elsif values.is_a?(String)
      name_value = values
      id_value = params[:to_id]
    else
      name_value = values.path.map(&:name).join("->")
      id_value = values.id
    end
    (text_field_tag("art_#{to_id}", name_value, options.merge({:id => "art_#{input_id}"})) + hidden_field_tag(to_id, id_value, :droptree_id => "art_#{input_id}", :name => options[:input_name] )).html_safe
  end

  # 提示
  def span_hint(text)
    "<span class='hint'>#{text}</span>".html_safe
  end

  # 页面内的小标题
  def leg(text)
    "<legend><h4>#{text}</h4></legend>".html_safe
  end

  # n数字转化为人名币大写
  def number_to_capital_zh(n)
    cNum = ["零","壹","贰","叁","肆","伍","陆","柒","捌","玖","-","-","万","仟","佰","拾","亿","仟","佰","拾","万","仟","佰","拾","元","角","分"]
    cCha = [['零元','零拾','零佰','零仟','零万','零亿','亿万','零零零','零零','零万','零亿','亿万','零元'],[ '元','零','零','零','万','亿','亿','零','零','万','亿','亿','元']]

    i = 0
    sNum = ""
    sTemp = ""
    result = ""
    tmp = ("%.0f" % (n.abs.to_f * 100)).to_i
    return '零' if tmp == 0
    raise '整数部分加二位小数长度不能大于15' if tmp.to_s.size > 15
    sNum = tmp.to_s.rjust(15, ' ')

    for i in 0..14
      stemp = sNum.slice(i, 1)
      if stemp == ' '
        next
      else
        result += cNum[stemp.to_i] + cNum[i + 12];
      end
    end

    for m in 0..12
      result.gsub!(cCha[0][m], cCha[1][m])
    end

    if result.index('零分').nil? # 没有分时, 零角改成零
      result.gsub!('零角','零')
    else
      if result.index('零角').nil? # 有没有分有角时, 后面加"整"
        result += '整'
      else
        result.gsub!('零角', '整')
      end
    end

    result.gsub!('零分', '')
    "#{n < 0 ? "负" : ""}#{result}"
  end

  # 步骤条20160419
  def step_bar(bars, current)
    step_size = bars.size
    content_html = content_tag :ul, class: 'anchor' do 
      index = 0
      bars.map do |bar|
        current_step = current.is_a?(Array) ? current[0]  : current.to_i
        urls = current.is_a?(Array) ? current : []
        index += 1
        class_name = if index == current_step 
            "selected"
          elsif index > current_step && urls[index].present?
            "can" 
          elsif index > current_step
            "disabled" 
          else
            "done"
          end
        if bar[:desc].present?
          small_html = "<br><small>#{bar[:desc]}</small>"
          small_class = "stepDesc"
        else
          small_class = "span_special "
          small_html = ""
        end
        href = urls[index].blank? ? "" : "href='#{urls[index]}'"
        content_tag :li do 
          %Q|
            <a class="#{class_name} #{'cursor_default' if href.blank?}" #{href}>
              <label class="stepNumber #{'cursor_default' if href.blank?}">#{index}</label>
              <span class="#{small_class}  #{'cursor_default' if href.blank?}">
                #{bar[:title]}
                #{small_html}
              </span>
            </a>
          |.html_safe  
        end
      end.join(" ").html_safe
    end
    # content_tag(:h4, "当前流程", class: 'f14 pl20 slide_next b-tn1') + 
    content_tag(:div, content_html, class: 'swMain')
  end

  def step_bar_obj(obj, current = nil)
    bars = obj.is_a?(Array) ? obj : obj.class::STEP_BAR
    current = current || obj.current_step(current_user)
    step_bar(bars, current)
  end

  def step_bar_ui(bars, current)
    content_tag :ul, class: "ui-step list-unstyled" do 
      index = 0
      bars.map do |bar|
        index += 1
        current_step = current.is_a?(Array) ? current[0]  : current.to_i
        urls = current.is_a?(Array) ? current : []
        class_name = if index == current_step 
            "current"
          elsif index > current_step && urls[index].present?
            "can" 
          elsif index > current_step
            "disabled" 
          else
            "done"
          end
        class_w = "w#{bar.size * 18}"  
        %Q|
          <li class="step-item #{class_name} #{class_w}">
            #{'<b class="arrow-space"></b>' unless index == bars.size}
            <b class="arrow-bg"></b>
            #{urls[index].present? ? '<a href="' + urls[index] + '">'+ bar + '</a>' : bar}
          </li>
        |.html_safe
      end.join(" ").html_safe
    end
  end

  def step_bar_ui_obj(obj)
    bars = obj.class::STEP_BAR_UI
    current = obj.current_step_ui(current_user)
    step_bar_ui(bars, current) if current
  end

  # 进度条20160419
  def process_bar(value)
    style = if value <= 10
        'red'
      elsif value <= 70
        'orange'
      elsif value <= 90
        'blue'
      elsif value >= 100
        'green'
      end
    %Q|
      <div class="process-bar skin-#{style}">
        <div class="pb-wrapper">
        <div class="pb-container">
        <div class="pb-text">#{value}%</div>
        <div class="pb-value" style="width:#{value}%"></div>
      </div>
    |.html_safe  
  end 

  # 替换招标公告
  def info_g(info)
    ZtbTextMb::GS.each do |h|
      info = info.gsub(/#{h[:text]}/, eval(h[:code]).to_s)
    end
    info.html_safe
  end

  def number_tag(num, title = nil, desc = nil)
    html_num = "<b class='item_size art_tip_hover' title='#{title}'>#{num}</b>"
    html = if desc
    %Q|
      <b class="item_size art_tip_hover" title="#{title}">
        #{num}
      </b>
      <span class="hide">
        #{desc}
      </span>
    |
    else
      "<b class='item_size' title='#{title}'>#{num}</b>"
    end
    html.html_safe
  end

  # 初审项信息
  def fc_info(package, show_label = true)
    html = show_label ? label_tag("初审项", "info") : ""
    html += "<b class='item_size art_tip_hover' title='已关联的初审项'>#{package.first_checks.count}</b>".html_safe
    html += "<span class='hide'>#{package.first_checks.map{|fc| fc.intro }.join('<br/>').html_safe}</span>".html_safe
    html.html_safe
  end

  # 评分信息
  def pf_info(package, show_label = true)
    html = show_label ? label_tag("评分办法", "info") : ""
    html += link_to_blank package.pfbf.name, show_pfbf_ancient_ztb_project_path(package.ztb_project_id, pfbf_id: package.pfbf.id)
    html.html_safe
  end

  # # 将信息按照一列显示
  # def show_in_group
  #   div = content_tag :div, text, class: 'show_in_group'
  #   js = '$(document).ready(function(){
  #         '
  #    js += ""
  #   js += "$('[slide_dom_id]').each(function(){
  #       $(this).removeClass('slide_next').removeClass('slide_next_click').addClass('slide_dom');
  #     });"

   
  #   js += '});'
  #   div.html_safe + javascript_tag(js)
  # end
  
end
