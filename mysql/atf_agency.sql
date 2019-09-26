select concat(
    '*16','\r\n','$5','\r\n','hmset','\r\n',
    '$',LENGTH(id)+6,'\r\n','agency',id,'\r\n',
    '$4','\r\n','name','\r\n',
    '$',LENGTH(name),'\r\n',name,'\r\n',
    '$',LENGTH('agency_id'),'\r\n','agency_id','\r\n',
    '$',LENGTH(agency_id),'\r\n',agency_id,'\r\n',
    '$3','\r\n','pid','\r\n',
    '$',LENGTH(pid),'\r\n',pid,'\r\n',
    '$',LENGTH('validity_date'),'\r\n','validity_date','\r\n',
    '$',LENGTH(validity_date),'\r\n',validity_date,'\r\n',
    '$',LENGTH('total_subject_count'),'\r\n','total_subject_count','\r\n',
    '$',LENGTH(total_subject_count),'\r\n',total_subject_count,'\r\n',
    '$',LENGTH('use_subject_count'),'\r\n','use_subject_count','\r\n',
    '$',LENGTH(use_subject_count),'\r\n',use_subject_count,'\r\n',
    '$',LENGTH('create_time'),'\r\n','create_time','\r\n',
    '$',LENGTH(create_time),'\r\n',create_time,'\r\n'
--     '$',LENGTH('financial_restrict'),'\r\n','financial_restrict','\r\n',
--     '$',LENGTH(financial_restrict),'\r\n',financial_restrict,'\r\n'
,'\r') as f
from atf_agency order by id ASC