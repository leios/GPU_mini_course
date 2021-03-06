using KernelAbstractions, CUDAKernels, Test, CUDA

if has_cuda_gpu()
    CUDA.allowscalar(false)
end

# Simple kernel for matrix multiplication
@kernel function vec_add_kernel!(a, b, c)
    i, j = @index(Global, NTuple)

    c[i,j] = a[i,j] + b[i,j]
end

# Creating a wrapper kernel for launching with error checks
function vec_add!(a, b, c)
    if size(a)[2] != size(b)[1]
        println("Matrix size mismatch!")
        return nothing
    end
    if isa(a, Array)
        kernel! = vec_add_kernel!(CPU(),4)
    else
        kernel! = vec_add_kernel!(CUDADevice(),256)
    end
    kernel!(a, b, c, ndrange=size(c)) 
end

@testset "CPU+GPU kernels" begin
    a = rand(256, 256)
    b = rand(256, 256)
    c = zeros(256, 256)

    # beginning CPU tests, returns event
    ev = vec_add!(a,b,c)
    wait(ev)

    @test isapprox(c, a+b)

    # beginning GPU tests
    if has_cuda_gpu()
        d_a = CuArray(a)
        d_b = CuArray(b)
        d_c = CuArray(c)

        ev = vec_add!(d_a, d_b, d_c)
        wait(ev)

        @test isapprox(Array(d_c), a+b)
    end
end
