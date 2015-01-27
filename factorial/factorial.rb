def factorial(x)
       if (x == 0) #convention
                return 1
        end

        (1.. x).inject(:*)
end
