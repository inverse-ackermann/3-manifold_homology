using ResumableFunctions
using GAP


const s_char = ["G.1", "G.2"]
const char = ["*G.1", "*G.2", "*G.1^-1", "*G.2^-1"]

const transitions = 
    [1 2 4; 
     2 3 1; 
     3 4 2;
     4 1 3]

# current character, shift -> next character
# 1 1 -> 1
# 1 2 -> 2
# 1 3 -> 4

# 2 1 -> 2
# 2 2 -> 3
# 2 3 -> 1

# 3 1 -> 3
# 3 2 -> 4
# 3 3 -> 2

# 4 1 -> 4
# 4 2 -> 1
# 4 3 -> 3

struct Relator
    word::String
    num_a::Int64
    num_b::Int64
end


function relators_enc(length::Int64)
    Iterators.product(1:2, ntuple(i->1:3, length - 1)...)
end


@resumable function relators(length::Int64)
    for enc in relators_enc(length)
        (ind, cons...) = enc
        t = s_char[ind]
        
        num_a = ind == 1 ? 1 : 0
        num_b = ind == 2 ? 1 : 0
            
        for i in cons
            ind = transitions[ind, i] 
            t *= char[ind]
            
            if ind == 1
                num_a += 1
            elseif ind == 2
                num_b += 1
            elseif ind == 3
                num_a -= 1
            else
                num_b -= 1
            end
        end

        @yield Relator(
            t,
            num_a,
            num_b,
        )
    end
end


@resumable function perfect_presentations(min_len::Int64, max_len::Int64)
    for i = min_len : max_len
        for j = min_len : i
            for r_0 in relators(i)
                for r_1 in relators(j)
                    det = r_0.num_a * r_1.num_b - r_0.num_b * r_1.num_a
                    if det == 1 || det == -1
                        @yield (r_0.word, r_1.word)
                    end
                end
            end
        end
    end
end



GAP.Globals.CosetTableDefaultMaxLimit = 500

function main()
    GAP.Globals.G = @gap "FreeGroup(\"a\", \"b\")"
    
    for (w_1, w_2) in perfect_presentations(3, 7)
        T = GAP.evalstr("G / [$w_1, $w_2]")

        order = try 
            order = GAP.Globals.Order(T)
        catch _
            Nothing
        end

        if order != Nothing && order != 1
            println((w_1, w_2, order))
        end
    end
end


main()



