function foo ( flag ) 
    print ( "enter foo" ) ;
    if 0 > flag then 
        print ( "leave foo" ) ;
        return - 1 
    elseif 0 < flag then 
        print ( "leave foo" ) ;
        return 1 
    end 
    print ( "leave foo" ) ;
    return 0 
end 
