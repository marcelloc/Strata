// Enumeration only: no model, allocation, kernel, host name or file paths.
#include "strata/sycl_device_check.hpp"
#include <iostream>

int main() try {
    bool usable = false;
    for (const auto& p : sycl::platform::get_platforms()) {
        std::cout << "platform=" << p.get_info<sycl::info::platform::name>() << '\n';
        for (const auto& d : p.get_devices()) {
            std::cout << "device=" << d.get_info<sycl::info::device::name>()
                      << " vendor_id=" << d.get_info<sycl::info::device::vendor_id>()
                      << " gpu=" << d.is_gpu()
                      << " driver=" << d.get_info<sycl::info::device::driver_version>()
                      << " global_bytes=" << d.get_info<sycl::info::device::global_mem_size>()
                      << " max_allocation_bytes=" << d.get_info<sycl::info::device::max_mem_alloc_size>()
                      << " host_usm=" << d.has(sycl::aspect::usm_host_allocations)
                      << " device_usm=" << d.has(sycl::aspect::usm_device_allocations);
            std::cout << " free_bytes=";
            try {
                if (d.has(sycl::aspect::ext_intel_free_memory))
                    std::cout << d.get_info<sycl::ext::intel::info::device::free_memory>();
                else std::cout << "unavailable";
            } catch (const sycl::exception&) { std::cout << "unavailable"; }
            std::cout << " subgroup_sizes=";
            for (auto n : d.get_info<sycl::info::device::sub_group_sizes>()) std::cout << n << ',';
            const auto problem = strata::sycl_device_problem(d);
            usable |= problem.empty();
            std::cout << "\ncapability_check=" << (problem.empty() ? "passed (inference untested)" : problem) << '\n';
        }
    }
    if (!usable) std::cerr << "No compatible Intel GPU is visible. Check the Intel driver, Level Zero runtime and ONEAPI_DEVICE_SELECTOR.\n";
    return usable ? 0 : 2;
} catch (const std::exception& e) {
    std::cerr << "SYCL enumeration failed: " << e.what()
              << "\nCheck the Intel driver and oneAPI runtime environment.\n";
    return 2;
}
