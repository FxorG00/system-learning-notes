## R1

```text
今天就是要来解析 header lines/header section 的

对于 (data,length):
complete:
    出现的 \r 的数量=出现的 \n 数量=出现的 \r\n 数量=k
    那么我们需要一个寻找某个字符串 desired 在 data 这个字符串的出现次数的 helper；    
    find_desired_str_count(data,length,desired,desired_length)
    
    但是需要注意，给的 (data,length) 可能是个 complete+suffix，所以我们需要识别出来 complete；也就是找到第一个 empty line；但是可能前缀单独一个 \r\n 作为一个 empty line，所以需要单独分讨 \r\n；
    然后其余情况找到第一个 \r\n\r\n，然后把前缀作为新的 length 去进行解析
    
    考虑 k 个 \r\n，那么就是有 k 个 line(每个 line 结尾都是 \r\n)
    需要一个 find_desired_str_postion 返回一个出现过的左端点 vector；用 std::move 接收返回的 vector
	那么 k 个 line 对应的区间我都是能找出来的
	写一个 check_legal_field，解析对象就是一行
	
	field-name ":" OWS field-value OWS CRLF
	
	OWS: 0 个/多个空白；空白包括 SP/HTAB
    SP   = space，普通空格，byte 0x20
    HTAB = horizontal tab，水平制表符，byte 0x09

	check_legal_field:
		去掉 \r\n 后至少 length>=2
        得到 : 个数，如果 : 个数 =0 则非法；
        记第一个 : 下标为 field_name_end，找到 field_name_end 后面第一个不为 WS 的下标，记为 field_value_begin;
        
        那么 field name: [0,field_name_end)
        然后 length-2 对应 \r，length-1 对应 \n
        所以我们要找到 length-3(包括自己) 往前第一个不为 WS 的位置，记为 field_value_end
        field value: [field_value_begin,field_value_end+1)

        然后来一个 check_legal_field_name:
            要求 field name 出现的 byte 都落在 token byte 集合
            然后我传的时候已经把结尾的 : 排除了；并且我们的 token byte 没有空格；所以直接 check byte就好了
			check_field_name_byte_helper(ch)
			
        check_legal_field_value:
            check 每个 byte 是否合法
            check_field_value_byte_helper
    	
    	到这里就 return true
    	
    要求最后一个 line 的长度为 0: empty line
	如果最终解析成功，那么需要先清空 output.headers；把 headers field 都 push_back 到 output 里面
	还需要一个 parse_field 去解析每个 field；注意解析出来的 name 需要统一转成小写（因为 field name 大小写不敏感）
needmore:
	只能是 
	...\r\n...\r\n...\r b=a+1
	...\r\n...\r\n... b=a
	因为单独的 \r\n 在 complete 被判断了；而且出现 \r\n 的前缀也不会进来 check needomore，所以不用理他。
	如果出现了 \r\n\r\n，那么一定不可以是 needmore，直接 return nullopt，也就是如果找到了 \r\n\r\n。
	
	分割成若干个 line 后，最后一个均可以为 empty line
	
	类似的形式，其中 \r\n 可以出现 0 次
	也就是我们记 \r\n 出现了 a 次，\r 出现了 b 次，\n 出现了 c 次。
	那么一定要 c=a
	并且若 b=a:
		则先 check 已经出现的 field 是否合法
		然后 check 最后一段是否可能是某个合法字段的前缀
		check_legal_field_prefix:
			如果 length=0，true
			否则 length>0:
				出现了冒号:
					直接按照 check_legal_field 去 check
				没出现冒号:
					意味着目前出现的都是 field name 字段
					那么 check_legal_field_name 即可
	若 b=a+1
		则最后一个 \r 一定要出现在最后一个 \r\n 后面
		那么 check 所有 field 是否合法即可

error:
    没被前面判定成 complete/needmore
```

