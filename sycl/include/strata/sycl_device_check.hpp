#pragma once
#include <sycl/sycl.hpp>
#include <algorithm>
#include <string>

namespace strata {
inline std::string sycl_device_problem(const sycl::device& d) {
    if (!d.is_gpu() || d.get_info<sycl::info::device::vendor_id>() != 0x8086)
        return "Select an Intel GPU with ONEAPI_DEVICE_SELECTOR=level_zero:gpu; run strata-sycl-diagnostic.";
    if (!d.has(sycl::aspect::usm_device_allocations) || !d.has(sycl::aspect::usm_host_allocations))
        return "The selected Intel GPU does not provide device and host USM allocations.";
    const auto sizes = d.get_info<sycl::info::device::sub_group_sizes>();
    if (std::find(sizes.begin(), sizes.end(), 32) == sizes.end())
        return "The selected Intel GPU does not support the required subgroup size 32.";
    if (!d.has(sycl::aspect::fp16)) return "The selected Intel GPU does not support fp16.";
    return {};
}
} // namespace strata
