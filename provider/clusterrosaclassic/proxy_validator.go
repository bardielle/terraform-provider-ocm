package clusterrosaclassic

import (
	"context"
	"fmt"
	"github.com/hashicorp/terraform-plugin-framework/types/basetypes"
	"github.com/openshift/rosa/pkg/helper"
	"github.com/terraform-redhat/terraform-provider-rhcs/provider/common"
	"strings"

	"github.com/hashicorp/terraform-plugin-framework/schema/validator"
)

// atLeastValidator validates that an integer Attribute's value is at least a certain value.
type proxyValidator struct {
}

// Description describes the validation in plain text formatting.
func (v proxyValidator) Description(_ context.Context) string {
	return fmt.Sprintf("proxy map should not include an hard coded OCM proxy")
}

// MarkdownDescription describes the validation in Markdown formatting.
func (v proxyValidator) MarkdownDescription(ctx context.Context) string {
	return v.Description(ctx)
}

// Validate performs the validation.
func (v proxyValidator) ValidateObject(ctx context.Context, request validator.ObjectRequest, response *validator.ObjectResponse) {
	if request.ConfigValue.IsNull() || request.ConfigValue.IsUnknown() {
		return
	}

	proxy := Proxy{}
	d := request.ConfigValue.As(ctx, &proxy, basetypes.ObjectAsOptions{})
	if d.HasError() {
		// No attribute to validate
		return
	}
	errSum := "Invalid proxy's attribute assignment"
	httpsProxy := ""
	httpProxy := ""
	additionalTrustBundle := ""
	var noProxySlice []string

	if !common.IsStringAttributeEmpty(proxy.HttpProxy) {
		httpProxy = proxy.HttpProxy.ValueString()
	}
	if !common.IsStringAttributeEmpty(proxy.HttpsProxy) {
		httpsProxy = proxy.HttpsProxy.ValueString()
	}
	if !common.IsStringAttributeEmpty(proxy.NoProxy) {
		noProxySlice = helper.HandleEmptyStringOnSlice(strings.Split(proxy.NoProxy.ValueString(), ","))
	}

	if !common.IsStringAttributeEmpty(proxy.AdditionalTrustBundle) {
		additionalTrustBundle = proxy.AdditionalTrustBundle.ValueString()
	}

	if httpProxy == "" && httpsProxy == "" && noProxySlice != nil && len(noProxySlice) > 0 {
		response.Diagnostics.AddError(errSum, "Expected at least one of the following: http-proxy, https-proxy")
		return
	}
	if httpProxy == "" && httpsProxy == "" && additionalTrustBundle == "" {
		response.Diagnostics.AddError(errSum, "Expected at least one of the following: http-proxy, https-proxy, additional-trust-bundle")
		return
	}
}

func ProxyValidator() validator.Object {
	return proxyValidator{}
}
