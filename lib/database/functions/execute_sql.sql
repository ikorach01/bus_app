create or replace function public.execute_sql(sql text)
returns json
language plpgsql
security definer
as $$
declare
    result json;
begin
    -- Execute the SQL
    execute sql;
    
    -- Return success
    return json_build_object('success', true);

exception when others then
    -- Return detailed error information
    return json_build_object(
        'success', false,
        'error', sqlstate,
        'message', sqlerrm,
        'detail', sqlerrdetail,
        'context', sqlerrcontext
    );
end;
$$;
